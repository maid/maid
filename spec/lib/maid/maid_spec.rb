require 'spec_helper'
require 'maid/maid'

module Maid
  describe Maid do
    before :each do
      @logger = mock('Logger')
      @logger.stub!(:progname=)
      Logger.stub!(:new).and_return(@logger)
    end

    describe '.new' do
      it 'should set up a logger with the default path' do
        Logger.should_receive(:new).with(Maid::DEFAULTS[:log_path])
        Maid.new
      end

      it 'should set up a logger with the given path, if provided' do
        log_path = '/var/log/maid.log'
        Logger.should_receive(:new).with(log_path)
        Maid.new(:log_path => log_path)
      end

      it 'should make the log directory in case it does not exist' do
        FileUtils.should_receive(:mkdir_p).with('/home/username/log')
        Maid.new(:log_path => '/home/username/log/maid.log')
      end

      it 'should set the trash to the default path' do
        maid = Maid.new
        maid.trash_path.should_not be_nil
        maid.trash_path.should == Maid::DEFAULTS[:trash_path]
      end

      it 'should set the trash to the given path, if provided' do
        trash_path = '/home/username/.local/share/Trash/files/'
        maid = Maid.new(:trash_path => trash_path)
        maid.trash_path.should_not be_nil
        maid.trash_path.should == trash_path
      end

      it 'should set the progname for the logger' do
        @logger.should_receive(:progname=).with(Maid::DEFAULTS[:progname])
        Maid.new
      end

      it 'should set the progname for the logger to the given name, if provided' do
        @logger.should_receive(:progname=).with('Fran')
        Maid.new(:progname => 'Fran')
      end
    end

    describe '#clean' do
      before :each do
        @maid = Maid.new
        @maid.stub!(:process_rules)
        @logger.stub!(:info)
      end

      it 'should log start and finish' do
        @logger.should_receive(:info).with('Started')
        @logger.should_receive(:info).with('Finished')
        @maid.clean
      end

      it 'should process the default rules' do
        @maid.should_receive(:process_rules).with(Maid::DEFAULTS[:rules_path])
        @maid.clean
      end

      it 'should process the given rules, if provided' do
        rules_path = '/home/username/.local/maid/rules.rb'
        @maid.should_receive(:process_rules).with(rules_path)
        @maid.clean(rules_path)
      end
    end

    describe '#process_rules' do
      before :each do
        @maid = Maid.new
      end

      it 'should require the path' do
        path = 'rules.rb'
        Kernel.should_receive(:require).with(path)
        @maid.process_rules(path)
      end
    end
  end
end
