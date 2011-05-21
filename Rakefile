require 'rake'
require 'rake/rdoctask'
require 'bundler'
Bundler::GemHelper.install_tasks

Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'doc'
  rd.main = 'README.rdoc'
  rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')  
end
