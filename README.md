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

The Ruby JSON parser unfortunately does not detect duplicate keys
in objects, so neither does statelint.

## Contributing

Bug reports and pull requests are welcome on GitHub 

### Testing

All changes should be covered by unit tests in the `spec` directory. To run tests, execute the following from the package root:

```
bundle exec rspec
```
