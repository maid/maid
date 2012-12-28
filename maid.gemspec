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
  s.license     = 'GPLv2'
  s.homepage    = 'http://github.com/benjaminoakes/maid'
  s.summary     = 'Be lazy.  Let Maid clean up after you, based on rules you define.  Think of it as "Hazel for hackers".'
  s.description = s.summary

  s.rubyforge_project = 'maid'

  s.add_dependency('thor', '~> 0.16.0')
  s.add_dependency('deprecated', '~> 3.0.1')
  s.add_dependency('ohai', '~> 6.14.0')
  s.add_dependency('xdg', '~> 2.2.3')
  s.add_development_dependency('fakefs', '~> 0.4.1')
  s.add_development_dependency('guard', '~> 1.6.1')
  s.add_development_dependency('guard-rspec', '~> 2.3.0')
  s.add_development_dependency('rake', '~> 10.0.2')
  s.add_development_dependency('redcarpet', '~> 2.2.2') # Soft dependency of `yard`
  s.add_development_dependency('rspec', '~> 2.12.0')
  s.add_development_dependency('timecop', '~> 0.5.3')
  s.add_development_dependency('yard', '~> 0.8.3')

  # In Vagrant, polling won't cross over the OS boundary if you develop in the host OS but run your tests in the
  # guest.  One way around this is to force polling instead:
  #
  #     bundle exec guard --force-polling
  #
  s.add_development_dependency('rb-inotify', '~> 0.8.8')
  s.add_development_dependency('rb-fsevent', '~> 0.9.2')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
