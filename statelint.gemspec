Gem::Specification.new do |s|
  s.name        = 'statelint'
  s.version     = '0.8.0'
  s.summary     = "State Machine JSON validator"
  s.description = "Validates a JSON object representing a State Machine"
  s.authors     = ["Tim Bray"]
  s.email       = 'timbray@amazon.com'
  s.executables << 'statelint'
  s.files       = `git ls-files`.split("\n").reject do |f|
    f.match(%r{^(spec|test)/})
  end

  s.homepage    = 'https://github.com/awslabs/statelint'
  s.license     = 'Apache-2.0'

  s.required_ruby_version = '>= 1.9.2'

  s.add_runtime_dependency 'j2119', '~> 0.4', '>= 0.4.0'

  s.metadata = {
    'source_code_uri' => 'https://github.com/awslabs/statelint',
    "bug_tracker_uri"   => 'https://github.com/awslabs/statelint/issues'
  }
end
