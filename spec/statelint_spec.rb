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

  it 'should reject empty ErrorEquals clauses' do
    j = File.read "test/empty-error-equals-on-catch.json"
    linter = StateMachineLint::Linter.new
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('non-empty required')
    
    j = File.read "test/empty-error-equals-on-retry.json"
    linter = StateMachineLint::Linter.new
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('non-empty required')
  end

  it 'should reject Parameters except in Pass, Task, and Parallel' do
    j = File.read "test/pass-with-parameters.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    problems.each { |p| puts "P: #{p}" }
    expect(problems.size).to eq(0)
    
    j = File.read "test/task-with-parameters.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    problems.each { |p| puts "P: #{p}" }
    expect(problems.size).to eq(0)

    j = File.read "test/choice-with-parameters.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"Parameters"')

    j = File.read "test/wait-with-parameters.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"Parameters"')

    j = File.read "test/succeed-with-parameters.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"Parameters"')

    j = File.read "test/fail-with-parameters.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"Parameters"')

    j = File.read "test/parallel-with-parameters.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should reject non-Path constructs in Parameter fields ending in ".$"' do
    j = File.read "test/parameter-path-problems.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(4)
    expect(problems[0]).to include('bad1')
    expect(problems[1]).to include('bad2')
    expect(problems[2]).to include('bad3')
    expect(problems[3]).to include('bad4')
  end

  it 'should reject ResultPath except in Pass, Task, and Parallel' do
    j = File.read "test/pass-with-resultpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    problems.each { |p| puts "P: #{p}" }
    expect(problems.size).to eq(0)

    j = File.read "test/task-with-resultpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    problems.each { |p| puts "P: #{p}" }
    expect(problems.size).to eq(0)

    j = File.read "test/choice-with-resultpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultPath"')

    j = File.read "test/wait-with-resultpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultPath"')

    j = File.read "test/succeed-with-resultpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultPath"')

    j = File.read "test/fail-with-resultpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultPath"')

    j = File.read "test/parallel-with-resultpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
    
  end

end
