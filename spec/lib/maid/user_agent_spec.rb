require 'spec_helper'

module Maid
  describe UserAgent do
    describe 'the user agent string' do
      it 'is formatted with the Maid version, platform version, and Ruby version' do
        system = {
          'platform' => 'Unix',
          'platform_version' => '1.0',
        }

        system.stub(:all_plugins)

        Ohai::System.stub(:new) { system }
        stub_const('RUBY_VERSION', '1.8.8')
        stub_const('RUBY_PLATFORM', 'pdp7')
        ::Maid.stub(:const_get).with(:VERSION) { '0.0.1' }

        UserAgent.value.should == 'Maid/0.0.1 (Unix/1.0; Ruby/1.8.8 pdp7)'
      end
    end
  end
end
