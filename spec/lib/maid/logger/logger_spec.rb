require 'spec_helper'
require 'maid/logger/logger'

module Maid
  describe Logger do
    let(:logfile) { '/tmp/maid/test.log' }
    let(:logger) { described_class.new(device: logfile) }

    # FakeFS not required because we're writing the log to /tmp/ and deleting
    # it after the test.
    after { FileUtils.rm('/tmp/maid/test.log', force: true) }

    levels = %i[debug info warn error fatal unknown]
    levels.each do |level|
      it "responds to #{level}" do
        expect(logger).to respond_to(level)
      end
    end

    context 'with a filename' do
      before { logger.info('hello') }

      it 'creates that file' do
        expect(File.exist?(logfile)).to be true
      end

      context 'with the ::Logger::DEBUG log level' do
        let(:logger) { described_class.new(device: logfile, level: ::Logger::DEBUG) }

        levels.each do |level|
          it "logs #{level} messages" do
            logger.send(level, "#{level} test message")

            expect(File.read(logfile)).to match("#{level} test message")
          end
        end
      end

      it 'works with a string' do
        logger.info('test message')

        expect(File.read(logfile)).to match 'test message'
      end

      it 'works with a custom progname and a block' do
        logger.info('TestProgname') { 'test message' }

        expect(File.read(logfile)).to match 'TestProgname: test message'
      end
    end

    context 'with an IO' do
      let(:logger) { described_class.new(device: $stderr) }

      before { logger.info('hello') }

      it "doesn't create a file" do
        expect(File.exist?('$stderr')).to be false
        expect(File.exist?('STDERR')).to be false
      end
    end
  end
end
