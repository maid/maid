require 'rubygems'
require 'rspec'
require 'timecop'
require 'fakefs/spec_helpers'

require 'maid'

RSpec.configure do |config|
  config.mock_with(:rspec) do |mock_config|
    mock_config.syntax = [:should, :expect]
  end

  config.include(FakeFS::SpecHelpers, :fakefs => true)
end

RSpec::Matchers.define :have_deprecated_method do |expected|
  match do |actual|
    actual.should_receive(:__deprecated_run_action__).with(expected, anything)
  end
end
