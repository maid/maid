# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'maid/version'

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

  s.required_ruby_version = Gem::Requirement.new('>= 1.9.3')

  # Strategy: if possible, use ranges (so there are fewer chances of version conflicts)
  s.add_dependency('escape', '>= 0.0.1', '< 0.1.0') # Used for better Ruby 1.8.7 support, could be replaced with `Shellwords`
  s.add_dependency('thor', '>= 0.14.0', '< 0.19.0')
  s.add_dependency('deprecated', '~> 3.0.0')
  s.add_dependency('mime-types', '~> 1.21') # TODO: loosen version restrictions based on testing
  s.add_dependency('rubyzip', '~> 1.0.0')
  s.add_dependency('xdg', '~> 2.2.3') # previous versions had bugs
  # TODO: use one of these two gems instead of `mdfind`.  **But** They have to work on Linux as well.
  #
  #     s.add_dependency('mac-spotlight', '~> 0.0.4')
  #     s.add_dependency('spotlight', '~> 0.0.6')

  # Strategy: specific versions (since they're just for development)
  s.add_development_dependency('fakefs', '~> 0.4.2')
  s.add_development_dependency('guard', '~> 2.2.2')
  s.add_development_dependency('guard-rspec', '~> 4.0.3')
  s.add_development_dependency('rake', '~> 10.1.0')
  s.add_development_dependency('redcarpet', '~> 3.0.0') # Soft dependency of `yard`
  s.add_development_dependency('rspec', '~> 2.14.1')
  s.add_development_dependency('timecop', '~> 0.6.3')
  s.add_development_dependency('yard', '~> 0.8.4')

  # In Vagrant, polling won't cross over the OS boundary if you develop in the host OS but run your tests in the
  # guest.  One way around this is to force polling instead:
  #
  #     bundle exec guard --force-polling
  #
  s.add_development_dependency('rb-inotify', '~> 0.9.0')
  s.add_development_dependency('rb-fsevent', '~> 0.9.2')

  s.files         = `git ls-files -z`.split("\0")
  s.test_files    = `git ls-files -z -- {test,spec,features}/*`.split("\0")
  s.executables   = `git ls-files -z -- bin/*`.split("\0").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
