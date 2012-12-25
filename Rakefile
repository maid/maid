require 'bundler'
require 'rake'
require 'rspec/core/rake_task'
require 'yard'

task :default => :spec

Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec)
YARD::Rake::YardocTask.new

task :console do
  sh('irb -I lib -r maid')
end
