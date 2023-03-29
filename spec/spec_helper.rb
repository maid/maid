# frozen_string_literal: true

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/lib/maid/rules.sample.rb"
    minimum_coverage 82.77
    refuse_coverage_drop
  end
end
require 'rubygems'
require 'rspec'
require 'timecop'
require 'fakefs/spec_helpers'
require 'pry-byebug'

require 'maid'

RSpec.configure do |config|
  config.mock_with(:rspec) do |mocks|
    mocks.allow_message_expectations_on_nil = false
  end
  config.include(FakeFS::SpecHelpers, fakefs: true)
  config.raise_errors_for_deprecations!
end

RSpec::Matchers.define :have_deprecated_method do |expected|
  match do |actual|
    expect(actual).to receive(:__deprecated_run_action__).with(expected, anything) # rubocop:disable RSpec/MessageSpies
  end
end
