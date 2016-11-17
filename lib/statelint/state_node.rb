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

module StateMachineLint

  # Semantic validation on state nodes that can't be expressed in a
  #  J2119 schema
  #
  class StateNode

    def initialize
      @nexts = {}
      @states = {}
    end

    def check(node, path, problems)
      if !node.is_a? Hash
        return
      end

      check_StartAt_States(node, path, problems)
      check_next(node, path)

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
    end

    def check_linkages(problems)
      @nexts.keys.each do |next_val|
        if !@states[next_val]
          problems <<
            "State \"#{next_val}\" not found, " +
            "referenced at #{@nexts[next_val]}"
        end
      end

      @states.keys.each do |state_name|
        if !@nexts[state_name]
          problems <<
            "No transition found to state \"#{state_name}\" " +
            "defined at #{@states[state_name]}.States"
        end
      end
    end

    def check_next(node, path)
      add_next(node, path, 'Next')
      add_next(node, path, 'Default')
    end

    def add_next(node, path, field)
      if node[field] && node[field].is_a?(String)
        next_val = node[field]
        @nexts[next_val] = path  # over-write is OK
      end
    end

    def check_StartAt_States(node, path, problems)

      # Is there a StartAt field that points at one of the children?
      if node['States'] && node['StartAt'] && node['StartAt'].is_a?(String)

        @nexts[node['StartAt']] = path + ".StartAt"
        node['States'].keys.each do |state_name|
          if @states[state_name]
            problems <<
              "State name #{state_name} occurs at " + @states[state_name] +
              " and also at " + path
          end
          @states[state_name] = path
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

