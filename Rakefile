require 'rake'
require 'rake/rdoctask'
require 'rspec/core/rake_task'
require 'bundler'

task :default => :spec

Bundler::GemHelper.install_tasks

Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'doc'
  rd.main = 'README.rdoc'
  rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')  
end

RSpec::Core::RakeTask.new(:spec)

task :console do
  sh 'irb -I lib -r maid'
end
