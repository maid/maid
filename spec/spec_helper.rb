# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/lib/maid/rules.sample.rb'
    # as seen on ubuntu-latest on CI. macos reports a slightly lower number for
    # some reason.
    minimum_coverage 82.77
    refuse_coverage_drop
  end
end
require 'rubygems'
require 'rspec'
require 'timecop'
require 'fakefs/spec_helpers'
require 'pry-byebug'
require 'vcr'

require 'maid'

# Prevent running RSpec unless it's running in Vagrant or Docker, to avoid
# overwriting files on the live filesystem through the tests.
unless ENV['ISOLATED']
  raise "It's safer to run the tests within a Docker container or a Vagrant box.
  See https://github.com/maid/maid/wiki/Contributing. To run anyway, set the
  environment variable `ISOLATED` to `true`"
end

RSpec.configure do |config|
  config.mock_with(:rspec) do |mocks|
    mocks.allow_message_expectations_on_nil = false
  end
  config.include(FakeFS::SpecHelpers, fakefs: true)
  config.raise_errors_for_deprecations!

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # NOTE: If a test fails because ENOENT /usr/share/zoneinfo/Africa/Abidjan,
  # add `fake_zoneinfo: true` to the describe:
  # `describe(MyClass, fake_zoneinfo: true do`
  config.before(:context, fake_zoneinfo: true) do
    # Rufus needs zoneinfo data to run, but when using FakeFS,
    # /usr/share/zoneinfo doesn't exist on the FakeFS.
    # On Linux, we just have to FakeFS::FileSystem.clone the directory and it
    # just works.
    # OSX is, of course, special. /usr/share/zoneinfo is a symlink on that
    # platform, and `.clone` doesn't seem to be following symlinks. Instead, we
    # have to copy the zoneinfo data to a temporary directory on the live
    # filesystem, enable the FakeFS, clone that temporary directory, create
    # /usr/share/zoneinfo onto the FakeFS, and finally copy the files into it.
    # This way, they're available in the FakeFS where Rufus can find them.
    include FakeFS::SpecHelpers
    FakeFS.activate!

    if Maid::Platform.osx?
      FakeFS.deactivate!
      FileUtils.mkdir_p('/tmp/')
      FileUtils.cp_r('/usr/share/zoneinfo/', '/tmp/')
      FakeFS.activate!
      FakeFS::FileSystem.clone('/tmp/zoneinfo/')
      FileUtils.mkdir_p('/usr/share/')
      FileUtils.cp_r('/tmp/zoneinfo/', '/usr/share/')
    end

    FakeFS::FileSystem.clone('/usr/share/zoneinfo') if Maid::Platform.linux?
  end
end

RSpec::Matchers.define :have_deprecated_method do |expected|
  match do |actual|
    expect(actual).to receive(:__deprecated_run_action__).with(expected, anything) # rubocop:disable RSpec/MessageSpies
  end
end

VCR.configure do |config|
  config.cassette_library_dir = 'fixtures/vcr_cassettes'
  config.hook_into :webmock
  # For autogenerating VCR cassettes' names based on the tests' metadata
  config.configure_rspec_metadata!
end
