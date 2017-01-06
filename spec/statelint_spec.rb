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
require 'json'
require 'statelint'

describe StateMachineLint do

  it 'should allow Fail states to omit optional Cause/Error fields' do
    j = File.read "test/minimal-fail-state.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

end
