require 'rubygems'
require 'rspec'
require 'timecop'
require 'fakefs/spec_helpers'

require 'maid'

RSpec.configure do |c|
  c.mock_with(:rspec)
  c.include(FakeFS::SpecHelpers, :fakefs => true)
end

RSpec::Matchers.define :have_deprecated_method do |expected|
  match do |actual|
    actual.should_receive(:__deprecated_run_action__).with(expected, anything)
  end
end
