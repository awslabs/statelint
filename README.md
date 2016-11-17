# statelint
A Ruby gem that provides a command-line validator for Amazon States Language JSON files. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'statelint'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install statelint

## Usage

statelint state-machine-spec, state-machinespec...

There are no options. If you see no output, your state machine is fine.

## To do

Currently covers most of the grammatical constraints for state-machine 
definitions.  The checking of JsonPath syntax is hand-built and probably
imperfect.

At the moment, does not catch linkages between top-level states
and nested Parallel branches.

Also, does not verify that a state machine has a terminal state.

## Contributing

Bug reports and pull requests are welcome on GitHub 

