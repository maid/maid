require 'spec_helper'

module Maid
  describe UserAgent do
    describe 'the user agent string' do
      it 'is formatted with the Maid version, platform version, and Ruby version' do
        stub_const('RUBY_DESCRIPTION', 'ruby 1.8.8p0 (1970-01-01 revision 1) [pdp7-unix]')
        ::Maid.stub(:const_get).with(:VERSION) { '0.0.1' }

        expect(UserAgent.value).to eq('Maid/0.0.1 (ruby 1.8.8p0 (1970-01-01 revision 1) [pdp7-unix])')
      end
    end

    describe 'the short user agent string' do
      it 'is formatted with the Maid version' do
        ::Maid.stub(:const_get).with(:VERSION) { '0.0.1' }
        expect(UserAgent.short).to eq('Maid/0.0.1')
      end
    end
  end
end
