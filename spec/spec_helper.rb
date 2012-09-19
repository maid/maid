require 'rubygems'
require 'rspec'
require 'timecop'
require 'fakefs/spec_helpers'

require 'maid'

Rspec.configure do |c|
  c.mock_with :rspec
  c.include FakeFS::SpecHelpers, :fakefs => true
end
