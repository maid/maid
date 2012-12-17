require 'spec_helper'

module Maid
  describe UserAgent do
    describe 'the user agent string' do
      it 'is formatted with the Maid version, platform version, and Ruby version' do
        system = {
          'platform' => 'Unix',
          'platform_version' => '1.0',
          'languages' => {
            'ruby' => {
              'version' => '1.8.8',
              'platform' => 'pdp7',
            }
          }
        }

        system.stub(:all_plugins)

        Ohai::System.stub(:new) { system }
        ::Maid.stub(:const_get).with(:VERSION) { '0.0.1' }

        UserAgent.value.should == 'Maid/0.0.1 (Unix/1.0; Ruby/1.8.8 pdp7)'
      end
    end
  end
end
