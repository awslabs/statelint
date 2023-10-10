# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#    http://aws.amazon.com/apache2.0/
#
# or in the LICENSE.txt file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
#!/usr/bin/env ruby

require 'j2119'

module StateMachineLint

  # Semantic validation that can't be expressed in a J2119 schema
  #
  class StateNode

    def initialize
      # We push States nodes on here when we traverse them.
      #  Then, whenever we find a "Next" or "Default" or "StartAt" node,
      #  we validate that the target is there, and record that that
      #  target has an incoming pointer
      #
      @current_states_node = []
      @current_states_incoming = []

      # We keep track of all the state names and complain about
      #  dupes
      @all_state_names = {}
      @payload_builder_fields = ["Parameters", "ResultSelector"]
      @context_object_access_fields = [{"field"=> "InputPath", "nullable"=> true}, {"field"=> "OutputPath", "nullable"=> true}, {"field"=>  "ItemsPath", "nullable"=> false}]
      @choice_state_nested_operators = ["And", "Or", "Not"]
      @intrinsic_invocation_regex = /^States\.(Format|Array|ArrayPartition|ArrayContains|ArrayRange|ArrayGetItem|ArrayLength|ArrayUnique|Base64Encode|Base64Decode|Hash|JsonMerge|JsonToString|StringToJson|MathRandom|MathAdd|StringSplit)\(.+\)$/
      @intrinsic_uuid_invocation_regex = /^States\.UUID\(\)$/
    end

    def check(node, path, problems)
      if !node.is_a? Hash
        return
      end

      is_machine_top = node.key?("States") && node['States'].is_a?(Hash)
      if is_machine_top
        @current_states_node << node['States']
        start_at = node['StartAt']
        if start_at && start_at.is_a?(String)
          @current_states_incoming << [ start_at ]
          if !node['States'].key?(start_at)
            problems <<
              "StartAt value #{start_at} not found in " +
              "States field at #{path}"
          end
        else
          @current_states_incoming << []
        end

        states = node['States']
        states.keys.each do |name|
          child = states[name]
          if child.is_a?(Hash)
            child_path = path + '.' + name
            probe_context_object_access(child, child_path, problems)
            @payload_builder_fields.each do |field_name|
              if child.key?(field_name)
                probe_payload_builder(child[field_name], child_path, problems, field_name)
              end
            end  
            if child.key?("Type") && child["Type"] == "Choice" && child.key?("Choices")
              probe_choice_state(child["Choices"], child_path + '.Choices' , problems)
            end
          end

          if @all_state_names[name]
            problems <<
              "State \"#{name}\", defined at #{path}.States, " +
              "is also defined at #{@all_state_names[name]}"
          else
            @all_state_names[name] = "#{path}.States"
          end
        end
      end

      check_for_terminal(node, path, problems)

      check_next(node, path, problems)

      check_States_ALL(node['Retry'], path + '.Retry', problems)
      check_States_ALL(node['Catch'], path + '.Catch', problems)

      node.each do |name, val|
        if val.is_a?(Array)
          i = 0
          val.each do |element|
            check(element, "#{path}.#{name}[#{i}]", problems)
            i += 1
          end
        else
          check(val, "#{path}.#{name}", problems)
        end
      end

      if is_machine_top
        states = @current_states_node.pop
        incoming = @current_states_incoming.pop
        missing = states.keys - incoming
        missing.each do |state|
          problems << "No transition found to state #{path}.#{state}"
        end
      end
    end

    def check_next(node, path, problems)
      add_next(node, path, 'Next', problems)
      add_next(node, path, 'Default', problems)
    end

    def add_next(node, path, field, problems)
      if node[field] && node[field].is_a?(String)
        transition_to = node[field]

        if !@current_states_node.empty?
          if @current_states_node[-1].key?(transition_to)
            @current_states_incoming[-1] << transition_to
          else
            problems <<
              "No state found named \"#{transition_to}\", referenced at " +
              "#{path}.#{field}"
          end
        end
      end
    end

    def probe_context_object_access(node, path, problems)
      @context_object_access_fields.each do |field|
        field_name = field["field"]
        nullable = field["nullable"]
        if node.key?(field_name)
          if !nullable && node[field_name].nil?
            problems << "Field \"#{field_name}\" defined at \"#{path}\" should be non-null"
            return
          end
          if !node[field_name].nil? and !is_valid_parameters_path?(node[field_name])
            problems << "Field \"#{field_name}\" defined at \"#{path}\" is not a JSONPath"
          end
        end
      end
    end

    def probe_choice_state(node, path, problems)
      if node.is_a?(Hash)
        if node.key?("Variable") && !is_valid_parameters_path?(node["Variable"])
          problems << "Field \"Variable\" of Choice state at \"#{path}\" is not a JSONPath"
        end
        @choice_state_nested_operators.each do |operator|
          if node.key?(operator)
            probe_choice_state(node[operator], path + '.' + operator, problems)
          end
        end 
      elsif node.is_a?(Array)
        node.size.times {|i| probe_choice_state(node[i], "#{path}[#{i}]", problems) }
      end
    end

    # Search through Parameters for object nodes and check field semantics
    def probe_payload_builder(node, path, problems, field_name)
      if node.is_a?(Hash)
        node.each do |name, val|
          if name.end_with? '.$'
            if !is_intrinsic_invocation?(val) && !is_valid_parameters_path?(val)
              problems << "Field \"#{name}\" of #{field_name} at \"#{path}\" is not a JSONPath or intrinsic function expression"
            end
          else
            probe_payload_builder(val, "#{path}.#{name}", problems, field_name)
          end
        end
      elsif node.is_a?(Array)
        node.size.times {|i| probe_payload_builder(node[i], "#{path}[#{i}]", problems, field_name) }
      end
    end

    def is_intrinsic_invocation?(val)
      if val.is_a?(String) && (val.match?(@intrinsic_invocation_regex) || val.match?(@intrinsic_uuid_invocation_regex))
        return true
      end
      return false
    end

    # Check if a string that ends with ".$" is a valid path
    def is_valid_parameters_path?(val)
      if !val.is_a?(String)
        return false
      end
      # If the value begins with “$$”, the first dollar character is stripped off and the remainder MUST be a Path.
      if val.start_with?("$$")
        path_to_check = val.gsub(/^\$/, "")
        J2119::JSONPathChecker.is_path?(path_to_check)
      else
        J2119::JSONPathChecker.is_path?(val)
      end
    end

    def check_for_terminal(node, path, problems)
      if node['States'] && node['States'].is_a?(Hash)
        terminal_found = false
        node['States'].each_value do |state_node|
          if state_node.is_a?(Hash)
            if [ 'Succeed', 'Fail' ].include?(state_node['Type'])
              terminal_found = true
            elsif state_node['End'] == true
              terminal_found = true
            end
          end
        end

        if !terminal_found
          problems << "No terminal state found in machine at #{path}.States"
        end
      end
    end

    def check_States_ALL(node, path, problems)
      if !node.is_a?(Array)
        return
      end

      i = 0
      node.each do |element|
        if element.is_a?(Hash)
          if element['ErrorEquals'].is_a?(Array)
            ee = element['ErrorEquals']
            if ee.include? 'States.ALL'
              if i != (node.size - 1) || ee.size != 1
                problems <<
                  "#{path}[#{i}]: States.ALL can only appear in the last " +
                  "element, and by itself."
              end
            end
          end
        end
        i += 1
      end
    end
  end
end

