# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'maid/version'
require 'maid/platform'

Gem::Specification.new do |s|
  s.name        = 'maid'
  s.version     = Maid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Benjamin Oakes']
  s.email       = %w(hello@benjaminoakes.com)
  s.license     = 'MIT'
  s.homepage    = 'http://github.com/benjaminoakes/maid'
  s.summary     = %q{Be lazy.  Let Maid clean up after you, based on rules you define.}
  s.description = s.summary

  s.rubyforge_project = 'maid'

  s.add_dependency('thor', '~> 0.16.0')
  s.add_dependency('deprecated', '~> 3.0.1')
  # Only used on Linux, but still required/tested on OSX
  # # After a new version with the Ruby 1.9 bugfix is released, change over to `xdg`
  # s.add_dependency('xdg', '~> 2.2.2')
  s.add_dependency('maid-xdg', '= 2.2.1.2')
  s.add_development_dependency('guard', '~> 1.5.4')
  s.add_development_dependency('guard-rspec', '~> 2.1.2')
  s.add_development_dependency('rake', '~> 10.0.2')
  s.add_development_dependency('rspec', '~> 2.12.0')
  s.add_development_dependency('timecop', '~> 0.5.3')
  s.add_development_dependency('fakefs', '~> 0.4.1')

  if Maid::Platform.linux?
    s.add_development_dependency('rb-inotify', '~> 0.8.8')
  elsif Maid::Platform.osx?
    s.add_development_dependency('rb-fsevent', '~> 0.9.2')
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
