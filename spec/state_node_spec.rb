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
require 'statelint/state_node'

describe StateMachineLint::StateNode do

  it 'should find missing StartAt targets' do
    json = '{ "StartAt": "x", ' +
           '  "States": {' +
           '    "y": {"Type":"Succeed"} ' +
           '  }'  +
           '}'

    json = JSON.parse json
    problems = []
    checker = StateMachineLint::StateNode.new
    checker.check(json, 'a.b', problems)
    checker.check_linkages(problems)
    expect(problems.size).to eq(2)
  end

  it 'should catch nested problems' do
    json = '{ "StartAt": "x", ' +
           ' "States": { ' +
           '  "x": {' +
           '   "StartAt": "z",' +
           '   "States": { ' +
           '    "w": 1' +
           '   }' +
           '  }' +
           ' }' +
           '}'
    json = JSON.parse json
    problems = []
    checker = StateMachineLint::StateNode.new
    checker.check(json, 'a.b', problems)
    checker.check_linkages(problems)
    expect(problems.size).to eq(2)
  end
  
  it 'should find States.ALL not in end position' do
    json = '{ "Retry": [' +
           '  { "ErrorEquals": [ "States.ALL", "other" ] },'  +
           '  { "ErrorEquals": [ "YET ANOTHER" ] } ' +
           ' ] ' +
           '}'
    json = JSON.parse json
    problems = []
    checker = StateMachineLint::StateNode.new
    checker.check(json, 'a.b', problems)
    expect(problems.size).to eq(1)
  end

  it 'should find States.ALL not by itself' do
    json = '{ "Retry": [' +
           '  { "ErrorEquals": [ "YET ANOTHER" ] }, ' +
           '  { "ErrorEquals": [ "States.ALL", "other" ] }'  +
           ' ] ' +
           '}'
    json = JSON.parse json
    problems = []
    checker = StateMachineLint::StateNode.new
    checker.check(json, 'a.b', problems)
    expect(problems.size).to eq(1)
  end

  it 'should use Default field correctly' do
    text = {
      "StartAt"=> "A",
      "States"=> {
        "A" => {
          "Type" => "Choice",
          "Choices" => [
            {
              "Variable" => "$.a",
              "Next" => "B"
            }
          ],
          "Default" => "C"
        },
        "B" => {
          "Type" => "Succeed"
        },
        "C" => {
          "Type" => "Succeed"
        }
      }
    }
    json = JSON.parse(JSON.pretty_generate(text))
    problems = []
    checker = StateMachineLint::StateNode.new
    checker.check(json, 'a.b', problems)
    checker.check_linkages(problems)
    expect(problems.size).to eq(0)
  end

  it "should find Next fields with targets that don't match state names" do
    text = {
      "StartAt"=> "A",
      "States"=> {
        "A" => {
          "Type" => "Pass",
          "Next" => "B"
        }
      }
    }
    json = JSON.parse(JSON.pretty_generate(text))
    problems = []
    checker = StateMachineLint::StateNode.new
    checker.check(json, 'a.b', problems)
    checker.check_linkages(problems)
    expect(problems.size).to eq(1)
  end

  it "should find un-pointed-to states" do
    text = {
      "StartAt"=> "A",
      "States"=> {
        "A" => {
          "Type" => "Succeed"
        },
        "X" => {
          "Type" => "Succeed"
        }
      }
    }
    json = JSON.parse(JSON.pretty_generate(text))
    problems = []
    checker = StateMachineLint::StateNode.new
    checker.check(json, 'a.b', problems)
    checker.check_linkages(problems)
    expect(problems.size).to eq(1)
  end
end
