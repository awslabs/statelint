Gem::Specification.new do |s|
  s.name        = 'statelint'
  s.version     = '0.0.1'
  s.date        = '2016-09-28'
  s.summary     = "State Machine JSON validator"
  s.description = "Validates a JSON object representing a State Machine"
  s.authors     = ["Tim Bray"]
  s.email       = 'timbray@amazon.com'
  s.executables << 'statelint'
  s.files       = [
    "lib/statelint.rb",
    "lib/statelint/state_node.rb",
    "data/StateMachine.j2119"
  ]
  s.homepage    =
    'http://rubygems.org/gems/statelint'
  s.license       = 'Apache 2.0'
  s.add_runtime_dependency "json"
  s.add_runtime_dependency "j2119"
end
