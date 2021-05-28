require 'pp'
require 'rubygems'
require 'rspec'
require 'timecop'
require 'fakefs/spec_helpers'

require 'maid'

RSpec.configure do |config|
  config.mock_with(:rspec)
  config.include(FakeFS::SpecHelpers, :fakefs => true)
end

RSpec::Matchers.define :have_deprecated_method do |expected|
  match do |actual|
    expect(actual).to receive(:__deprecated_run_action__).with(expected, anything)
  end
end
