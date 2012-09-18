require 'spec_helper'

module Maid
  describe Maid do
    before do
      @logger = double('Logger').as_null_object
      Logger.stub!(:new).and_return(@logger)
      FileUtils.stub(:mkdir_p)
    end

    describe '.new' do
      it 'should set up a logger with the default path' do
        Logger.should_receive(:new).with(Maid::DEFAULTS[:log_device], anything, anything)
        Maid.new
      end

      it 'should set up a logger with the given path, when provided' do
        log_device = '/var/log/maid.log'
        Logger.should_receive(:new).with(log_device, anything, anything)
        Maid.new(:log_device => log_device)
      end

      it 'should rotate the log with the default settings' do
        Logger.should_receive(:new).with(anything, Maid::DEFAULTS[:log_shift_age], Maid::DEFAULTS[:log_shift_size])
        Maid.new
      end

      it 'should rotate the log with the given settings, when provided' do
        Logger.should_receive(:new).with(anything, 42, 1_000_000)
        Maid.new(:log_shift_age => 42, :log_shift_size => 1_000_000)
      end

      it 'should make the log directory in case it does not exist' do
        FileUtils.should_receive(:mkdir_p).with('/home/username/log')
        Maid.new(:log_device => '/home/username/log/maid.log')
      end

      it 'should take a logger object during intialization' do
        Logger.unstub!(:new)
        maid = Maid.new(:logger => @logger)
        maid.logger.should == @logger
      end

      describe 'platform-specific behavior' do
        before do
          Platform.stub(:linux?)
          Platform.stub(:osx?)
          @home = File.expand_path('~')
        end

        context 'when running on Linux' do
          before do
            Platform.stub(:linux?) { true }
            XDG.stub(:[]).with('DATA_HOME') { "#{ @home }/.local/share" }
          end

          it 'should set the trash to the correct default path' do
            trash_path = "#{ @home }/.local/share/Trash/files/"
            FileUtils.should_receive(:mkdir_p).with(trash_path).once
            maid = Maid.new
            maid.trash_path.should == trash_path
          end
        end

        context 'when running on OS X' do
          before do
            Platform.stub(:osx?) { true }
          end

          it 'should set the trash to the correct default path' do
            trash_path = "#{ @home }/.Trash/"
            FileUtils.should_receive(:mkdir_p).with(trash_path).once
            maid = Maid.new
            maid.trash_path.should == trash_path
          end
        end

        context 'when running on an unsupported platform' do
          it 'does not implement trashing files' do
            lambda { Maid.new }.should raise_error(NotImplementedError)
          end
        end
      end

      it 'should set the trash to the given path, if provided' do
        trash_path = '/home/username/tmp/my_trash/'
        FileUtils.should_receive(:mkdir_p).with(trash_path).once
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

      it 'should set the file options to the defaults' do
        Maid.new.file_options.should == Maid::DEFAULTS[:file_options]
      end

      it 'should set the file options to the given options, if provided' do
        maid = Maid.new(:file_options => { :verbose => true })
        maid.file_options.should == { :verbose => true }
      end

      it 'should set the rules path' do
        Maid.new.rules_path.should == Maid::DEFAULTS[:rules_path]
      end

      it 'should set the ruels pathto the given path, if provided' do
        maid = Maid.new(:rules_path => 'Maidfile')
        maid.rules_path.should == 'Maidfile'
      end

      it 'should ignore nil options' do
        maid = Maid.new(:rules_path => nil)
        maid.rules_path.should == Maid::DEFAULTS[:rules_path]
      end
    end

    describe '#clean' do
      before do
        @maid = Maid.new
        @logger.stub!(:info)
      end

      it 'should log start and finish' do
        @logger.should_receive(:info).with('Started')
        @logger.should_receive(:info).with('Finished')
        @maid.clean
      end

      it 'should follow the given rules' do
        @maid.should_receive(:follow_rules)
        @maid.clean
      end
    end

    describe '#load_rules' do
      before do
        Kernel.stub!(:load)
        @maid = Maid.new
      end

      it 'should set the Maid instance' do
        ::Maid.should_receive(:with_instance).with(@maid)
        @maid.load_rules
      end

      it 'should give an error on STDERR if there is a LoadError' do
        Kernel.stub!(:load).and_raise(LoadError)
        STDERR.should_receive(:puts)
        @maid.load_rules
      end
    end

    describe '#rule' do
      before do
        @maid = Maid.new
      end

      it 'should add a rule to the list of rules' do
        @maid.rules.length.should == 0

        @maid.rule('description') do
          'instructions'
        end

        @maid.rules.length.should == 1
        @maid.rules.first.description.should == 'description'
      end
    end

    describe '#follow_rules' do
      it 'should follow each rule' do
        n = 3
        maid = Maid.new
        @logger.should_receive(:info).exactly(n).times
        rules = (1..n).map do |n|
          mock = mock("rule ##{ n }", :description => 'description')
          mock.should_receive(:follow)
          mock
        end
        maid.instance_eval { @rules = rules }

        maid.follow_rules
      end
    end

    describe '#cmd' do
      before do
        @maid = Maid.new
      end

      it 'should report `not-a-real-command` as not being a supported command' do
        lambda { @maid.cmd('not-a-real-command arg1 arg2') }.should raise_error(NotImplementedError)
      end

      it 'should report `echo` as a real command' do
        lambda { @maid.cmd('echo .') }.should_not raise_error(NotImplementedError)
      end
    end
  end
end
