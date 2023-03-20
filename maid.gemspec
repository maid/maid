# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'maid/version'

Gem::Specification.new do |s|
  s.name        = 'maid'
  s.version     = Maid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Benjamin Oakes', 'Coaxial']
  s.email       = ['hello@benjaminoakes.com', 'c+rubygems@64b.it']
  s.license     = 'GPLv2'
  s.homepage    = 'http://github.com/maid/maid'
  s.summary     = Maid::SUMMARY
  s.description = s.summary
  s.files       = Dir['lib/**/*.rb'] + Dir['bin/maid']
  s.metadata    = {
                    "bug_tracker_uri"   => "https://github.com/maid/maid/issues",
                    "changelog_uri"     => "https://github.com/maid/maid/blob/master/CHANGELOG.md",
                    "documentation_uri" => "https://github.com/maid/maid/blob/master/README.md",
                    "source_code_uri"   => "https://github.com/maid/maid",
                    "wiki_uri"          => "https://github.com/maid/maid/wiki"
                  }

  s.rubyforge_project = 'maid'

  s.required_ruby_version = '>= 2.7.0'

  # Strategy: if possible, use ranges (so there are fewer chances of version conflicts)
  s.add_dependency('escape', '>= 0.0.1', '< 0.1.0') # Used for better Ruby 1.8.7 support, could be replaced with `Shellwords`
  s.add_dependency('thor', '~> 1.2.1')
  s.add_dependency('deprecated', '~> 3.0.0')
  s.add_dependency('dimensions', '>= 1.0.0', '< 2.0')
  s.add_dependency('mime-types', '~> 3.0', '< 4.0')
  s.add_dependency('rubyzip', '~> 2.3.2')
  s.add_dependency('xdg', '~> 2.2.3') # previous versions had bugs
  s.add_dependency('listen', '~> 3.8.0')
  s.add_dependency('rufus-scheduler', '~> 3.8.2')
  s.add_dependency('exifr', '~> 1.3.10')
  s.add_dependency('geocoder', '~> 1.8.1')

  # TODO: use one of these two gems instead of `mdfind`.  **But** They have to work on Linux as well.
  #
  #     s.add_dependency('mac-spotlight', '~> 0.0.4')
  #     s.add_dependency('spotlight', '~> 0.0.6')

  # Strategy: specific versions (since they're just for development)
  s.add_development_dependency('fakefs', '~> 2.4.0')
  s.add_development_dependency('guard', '~> 2.18.0')
  s.add_development_dependency('guard-rspec', '~> 4.7.3')
  s.add_development_dependency('rake', '~> 13.0.6')
  s.add_development_dependency('redcarpet', '~> 3.6.0') # Soft dependency of `yard`
  s.add_development_dependency('rspec', '~> 3.12.0')
  s.add_development_dependency('timecop', '~> 0.9.6')
  s.add_development_dependency('yard', '>= 0.9.11')
  s.add_development_dependency('pry-byebug')
  s.add_development_dependency('guard-bundler', '~> 3.0.1')

  # In Vagrant, polling won't cross over the OS boundary if you develop in the host OS but run your tests in the
  # guest.  One way around this is to force polling instead:
  #
  #     bundle exec guard --force-polling
  #
  s.add_development_dependency('rb-inotify', '~> 0.10.1')
  s.add_development_dependency('rb-fsevent', '~> 0.11.2')

  s.files         = `git ls-files -z`.split("\0")
  s.test_files    = `git ls-files -z -- {test,spec,features}/*`.split("\0")
  s.executables   = `git ls-files -z -- bin/*`.split("\0").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  s.post_install_message = "🙏 Thank you for installing Maid, we hope it's " \
    "useful to you! Visit #{s.homepage} to report issues or contribute code."
end
