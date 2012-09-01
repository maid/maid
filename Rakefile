require 'fileutils'
require 'rake'
require 'rake/rdoctask'
require 'rspec/core/rake_task'
require 'bundler'

f_opts = { :verbose => true }

task :default => :spec

Bundler::GemHelper.install_tasks

Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'doc'
  rd.main = 'README.rdoc'
  rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')  
end

RSpec::Core::RakeTask.new(:spec)

namespace :build do
  # While other Linux distributions may work, the only officially supported one is Ubuntu.
  desc 'Build maid-*.deb into the pkg directory'
  task :ubuntu => :build do
    latest_gem = Dir.glob('pkg/maid-*.gem').last
    cmd = "fpm -s gem -t deb #{latest_gem}"
    puts cmd
    `#{cmd}`
    FileUtils.mv(Dir.glob('*.deb'), 'pkg/', f_opts)
  end
end

task :clean do
  FileUtils.rm_rf('doc', f_opts)
  FileUtils.rm_rf('pkg', f_opts)
end
