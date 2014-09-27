require 'bundler'
require 'maid'
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

Maid::Rake::Task.new :clean do
  # Clean up Rubinius-compilied Ruby
  trash(dir('**/*.rbc'))

  # Get rid of generated files
  trash('doc')
  trash('pkg')
  trash('tmp')
end
