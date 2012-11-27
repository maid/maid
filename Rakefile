require 'rake'
require 'rspec/core/rake_task'
require 'bundler'

task :default => :spec

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)

task :console do
  sh('irb -I lib -r maid')
end
