require 'fileutils'
require 'rake'
require 'rake/rdoctask'
require 'rspec/core/rake_task'
require 'bundler'
require 'mustache'

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

    FileUtils.mkdir_p("#{package_name}/DEBIAN", f_opts)

    Dir.glob('../ubuntu/*').each do |path|
      raw = File.read(path)
      rendered = Mustache.render(raw, doc)
      outfile = File.join(package_name, 'DEBIAN', File.basename(path, '.mustache'))

      File.open(outfile, 'w') do |f|
        f.puts(rendered)

        # The new file needs to have its 'x' bit set:
        #
        #     dpkg-deb: error: maintainer script `postinst' has bad permissions 664 (must be >=0555 and <=0775)
        f.chmod(0555)
      end
    end

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
