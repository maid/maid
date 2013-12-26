require 'spec_helper'

module Maid
  describe Platform do
    def stub_host_os(value)
      RbConfig::CONFIG.stub(:[]).with('host_os') { value }
    end

    describe 'determining the host OS' do
      it 'delegates to RbConfig' do
        stub_host_os('foo')
        expect(subject.host_os).to eq('foo')
      end
    end

    context 'when running on Ubuntu' do
      before do
        stub_host_os('linux-gnu')
      end

      it 'is identified as Linux' do
        expect(subject.linux?).to be(true)
      end

      it 'is not identified as OS X' do
        expect(subject.osx?).to be(false)
      end

      it 'locate is "locate"' do
        expect(Platform::Commands.locate).to match(/locate/)
      end
    end

    context 'when running on Mac OS X' do
      before do
        stub_host_os('darwin10.0')
      end

      it 'is not identified as Linux' do
        expect(subject.linux?).to be(false)
      end

      it 'is identified as OS X' do
        expect(subject.osx?).to be(true)
      end

      it 'locate is "mdfind"' do
        expect(Platform::Commands.locate).to match(/mdfind/)
      end
    end
  end
end
