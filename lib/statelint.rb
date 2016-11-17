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

$:.unshift("#{File.expand_path(File.dirname(__FILE__))}/../lib")
require 'j2119'
require 'statelint/state_node'

# This module calls the J2119 validator on the supplised input, and
#  then performs some States-Language specific semantic checks that
#  aren't expressible in a J2119 schema

module StateMachineLint

  # TODO: Semantic validations:
  # - Path and Reference Path validations
  class Linter

    def initialize
      schema = File.dirname(__FILE__) + '/../data/StateMachine.j2119'
      @validator = J2119::Validator.new schema
    end

    def validate json
      problems = @validator.validate json
      checker = StateNode.new
      checker.check(@validator.parsed, @validator.root, problems)
      checker.check_linkages(problems)
      problems
    end
  end
end
