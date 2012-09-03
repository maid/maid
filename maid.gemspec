# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "maid/version"

Gem::Specification.new do |s|
  s.name        = "maid"
  s.version     = Maid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = 'GPL-2'
  s.author     = "Benjamin Oakes"
  s.email       = "hello@benjaminoakes.com"
  s.homepage    = "http://github.com/benjaminoakes/maid"
  s.summary     = %q{Be lazy.  Let Maid clean up after you, based on rules you define.}
  s.description = s.summary

  s.rubyforge_project = "maid"

  s.add_dependency('thor', '~> 0.14.6')
  s.add_development_dependency('rake', '~> 0.8.7')
  s.add_development_dependency('rspec', '~> 2.5.0')
  s.add_development_dependency('timecop', '~> 0.3.5')
  s.add_development_dependency('ZenTest', '~> 4.4.2')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
