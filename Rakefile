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
  #
  # See also: Ubuntu.md
  desc 'Build maid_*_all.deb into the pkg directory'
  task :ubuntu => :clean do
    Dir.chdir('pkg')
    doc = { :version => Maid::VERSION }
    package_name = "maid_#{doc[:version]}_all"

    FileUtils.mkdir_p(package_name, f_opts)
    FileUtils.cp_r('../ubuntu/DEBIAN', package_name)
    sh "dpkg --build #{package_name}"
  end
end

task :clean do
  recreate_dir = lambda do |path|
    FileUtils.rm_rf(path, f_opts)
    FileUtils.mkdir(path, f_opts)
  end

  recreate_dir.call('doc')
  recreate_dir.call('pkg')
end
