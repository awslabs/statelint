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

  it 'should allow Fail states to use ErrorPath and CausePath fields' do
    j = File.read "test/fail-with-error-and-cause-path.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow Fail states to use ErrorPath and CausePath fields with intrinsic functions' do
    j = File.read "test/fail-with-error-and-cause-path-using-intrinsic-functions.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should reject Fail state with both static and dynamic error/cause' do
    j = File.read "test/fail-with-static-and-dynamic-error.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('may have only one of ["Error", "ErrorPath"]')

    j = File.read "test/fail-with-static-and-dynamic-cause.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('may have only one of ["Cause", "CausePath"]')
  end

  it 'should allow Retry to use MaxDelaySeconds and JitterStrategy' do
    j = File.read "test/backoff-with-jitter-on-retry.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should reject invalid JitterStrategy' do
    j = File.read "test/backoff-with-invalid-jitter-on-retry.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('not one of the allowed values ["FULL", "NONE"]')
  end

  it 'should reject invalid MaxDelaySeconds' do
    j = File.read "test/invalid-backoff-with-jitter-on-retry.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('allowed floor is 0')
  end

  it 'should allow BackOffRate integer' do
    j = File.read "test/backoff-with-backoffrate-integer.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow BackOffRate decimal' do
    j = File.read "test/backoff-with-backoffrate-decimal.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should reject BackOffRate negative' do
    j = File.read "test/backoff-with-backoffrate-negative.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('allowed minimum is 1')
  end

  it 'should reject BackOffRate between 0 and 1' do
    j = File.read "test/backoff-with-backoffrate-between-0-and-1.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('allowed minimum is 1')
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

    j = File.read "test/map-with-parameters.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    puts problems
    expect(problems.size).to eq(0)
  end

  it 'should reject non-Path constructs in Parameter fields ending in ".$"' do
    j = File.read "test/parameter-path-problems.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(5)
    expect(problems[0]).to include('bad1')
    expect(problems[1]).to include('bad2')
    expect(problems[2]).to include('bad3')
    expect(problems[3]).to include('bad4')
    expect(problems[4]).to include('bad5')
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

  it 'should allow context object access in InputPath and OutputPath' do
    j = File.read "test/pass-with-io-path-context-object.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow context object access in Choice state Variable' do
    j = File.read "test/choice-with-context-object.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow context object access in Map state ItemsPath' do
    j = File.read "test/map-with-itemspath-context-object.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow dynamic timeout fields in Task state' do
    j = File.read "test/task-with-dynamic-timeouts.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow null values in InputPath and OutputPath' do
    j = File.read "test/pass-with-null-inputpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/pass-with-null-outputpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should not allow null value in Map state ItemsPath' do
    j = File.read "test/map-with-null-itemspath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ItemsPath"')
  end

  it 'should reject ResultSelector except in Task, Parallel, and Map states' do
    j = File.read "test/task-with-resultselector.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/parallel-with-resultselector.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/map-with-resultselector.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/pass-with-resultselector.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultSelector"')

    j = File.read "test/wait-with-resultselector.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultSelector"')

    j = File.read "test/fail-with-resultselector.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultSelector"')

    j = File.read "test/succeed-with-resultselector.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultSelector"')

    j = File.read "test/choice-with-resultselector.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"ResultSelector"')
  end

  it 'should allow only valid intrinsic function invocations in payload builder fields' do
    j = File.read "test/states-array-invocation.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-format-invocation.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-stringtojson-invocation.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-jsontostring-invocation.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-array-invocation-leftpad.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('not a JSONPath or intrinsic function expression')

    j = File.read "test/invalid-function-invocation.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('not a JSONPath or intrinsic function expression')

    j = File.read "test/pass-with-intrinsic-function-inputpath.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('"InputPath"')
  end

  it 'should reject Task state with both static and dynamic timeouts' do
    j = File.read "test/task-with-static-and-dynamic-timeout.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('may have only one of ["TimeoutSeconds", "TimeoutSecondsPath"]')

    j = File.read "test/task-with-static-and-dynamic-heartbeat.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
    expect(problems[0]).to include('may have only one of ["HeartbeatSeconds", "HeartbeatSecondsPath"]')
  end

  it 'should allow valid new intrinsic function invocations that were added in 2022' do
    j = File.read "test/states-array-intrinsic-functions.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-encoding-decoding-intrinsic-functions.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-hash-intrinsic-functions.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-json-intrinsic-functions.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-math-intrinsic-functions.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-string-intrinsic-functions.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)

    j = File.read "test/states-uuid-intrinsic-functions.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow Choice Rule to use Comment' do
    j = File.read "test/choice-rule-with-comment.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow Choice Rule Variable to use kebab-case JSON Path' do
    j = File.read "test/choice-rule-with-kebab-case-json-path.json"
    j = JSON.parse j
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow a Comment field in Catcher' do
    j = File.read "test/succeed-with-comment-in-catcher.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should allow ItemProcessor in Map' do
    j = File.read("test/map-with-itemprocessor.json")
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should reject Map state with both Iterator and ItemProcessor' do
    j = File.read("test/map-with-itemprocessor-and-iterator.json")
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
  end

  it 'should reject Map state with both Parameters and ItemSelector' do
    j = File.read("test/map-with-parameters-and-itemselector.json")
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
  end

  it 'should allow Credentials in Task' do
    j = File.read "test/task-with-credentials.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end

  it 'should reject invalid Credentials in Task' do
    j = File.read "test/task-with-invalid-credentials.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(1)
  end

  it 'should allow Comment in Nested Choice Rules' do
    j = File.read "test/choice-nested-comment.json"
    linter = StateMachineLint::Linter.new
    problems = linter.validate(j)
    expect(problems.size).to eq(0)
  end
end
