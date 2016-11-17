lib_dir = File.expand_path(File.join(File.dirname(__FILE__), "lib"))
$:.unshift(lib_dir)
$:.uniq!

require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new

