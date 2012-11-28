require 'bundler'
require 'rake'
require 'rspec/core/rake_task'
require 'yard'

task :default => :spec

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)

YARD::Rake::YardocTask.new do |t|
  t.files = %w(
    lib/maid/app.rb
    lib/maid/tools.rb
    lib/maid/numeric_extensions.rb
  )
  t.options = %w(--no-private)
end

task :console do
  sh('irb -I lib -r maid')
end
