require 'bundler'
require 'rake'
require 'rspec/core/rake_task'
require 'yard'
require 'rake/notes/rake_task'

task default: :spec

Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec)
YARD::Rake::YardocTask.new(:doc)

task :console do
  sh('irb -I lib -r maid')
end

require 'maid'

Maid::Rake::Task.new(:clean) do
  # Clean up Rubinius-compilied Ruby
  trash(dir('**/*.rbc'))

  # Get rid of generated files
  trash('doc')
  trash('pkg')
  trash('tmp')
end
