require 'spec_helper'

module Maid
  describe Maid do
    before do
      @logger = double('Logger').as_null_object
      Logger.stub(:new) { @logger }
      FileUtils.stub(:mkdir_p)
    end

    describe '.new' do
      it 'sets up a logger with the default path' do
        expect(Logger).to receive(:new).with(Maid::DEFAULTS[:log_device], anything, anything)
        Maid.new
      end

      it 'sets up a logger with the given path, when provided' do
        log_device = '/var/log/maid.log'
        expect(Logger).to receive(:new).with(log_device, anything, anything)
        Maid.new(:log_device => log_device)
      end

      it 'rotates the log with the default settings' do
        expect(Logger).to receive(:new).with(anything, Maid::DEFAULTS[:log_shift_age], Maid::DEFAULTS[:log_shift_size])
        Maid.new
      end

      it 'rotates the log with the given settings, when provided' do
        expect(Logger).to receive(:new).with(anything, 42, 1_000_000)
        Maid.new(:log_shift_age => 42, :log_shift_size => 1_000_000)
      end

      it 'makes the log directory in case it does not exist' do
        expect(FileUtils).to receive(:mkdir_p).with('/home/username/log')
        Maid.new(:log_device => '/home/username/log/maid.log')
      end

      it 'takes a logger object during intialization' do
        Logger.unstub(:new)
        maid = Maid.new(:logger => @logger)
        expect(maid.logger).to eq(@logger)
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

          it 'set the trash to the correct default path' do
            trash_path = "#{ @home }/.local/share/Trash/files/"
            expect(FileUtils).to receive(:mkdir_p).with(trash_path).once
            maid = Maid.new
            expect(maid.trash_path).to eq(trash_path)
          end
        end

        context 'when running on OS X' do
          before do
            Platform.stub(:osx?) { true }
          end

          it 'sets the trash to the correct default path' do
            trash_path = "#{ @home }/.Trash/"
            expect(FileUtils).to receive(:mkdir_p).with(trash_path).once
            maid = Maid.new
            expect(maid.trash_path).to eq(trash_path)
          end
        end

        context 'when running on an unsupported platform' do
          it 'does not implement trashing files' do
            expect(lambda { Maid.new }).to raise_error(NotImplementedError)
          end
        end
      end

      it 'sets the trash to the given path, if provided' do
        trash_path = '/home/username/tmp/my_trash/'
        expect(FileUtils).to receive(:mkdir_p).with(trash_path).once
        maid = Maid.new(:trash_path => trash_path)
        expect(maid.trash_path).not_to be_nil
        expect(maid.trash_path).to eq(trash_path)
      end

      it 'sets the progname for the logger' do
        expect(@logger).to receive(:progname=).with(Maid::DEFAULTS[:progname])
        Maid.new
      end

      it 'sets the progname for the logger to the given name, if provided' do
        expect(@logger).to receive(:progname=).with('Fran')
        Maid.new(:progname => 'Fran')
      end

      it 'sets the file options to the defaults' do
        expect(Maid.new.file_options).to eq(Maid::DEFAULTS[:file_options])
      end

      it 'sets the file options to the given options, if provided' do
        maid = Maid.new(:file_options => { :verbose => true })
        expect(maid.file_options).to eq(:verbose => true)
      end

      it 'sets the rules path' do
        expect(Maid.new.rules_path).to eq(Maid::DEFAULTS[:rules_path])
      end

      it 'sets the rules pathto the given path, if provided' do
        maid = Maid.new(:rules_path => 'Maidfile')
        expect(maid.rules_path).to eq('Maidfile')
      end

      it 'ignores nil options' do
        maid = Maid.new(:rules_path => nil)
        expect(maid.rules_path).to eq(Maid::DEFAULTS[:rules_path])
      end
    end

    describe '#clean' do
      before do
        @maid = Maid.new
        @logger.stub(:info)
      end

      it 'logs start and finish' do
        expect(@logger).to receive(:info).with('Started')
        expect(@logger).to receive(:info).with('Finished')
        @maid.clean
      end

      it 'follows the given rules' do
        expect(@maid).to receive(:follow_rules)
        @maid.clean
      end
    end

    describe '#load_rules' do
      before do
        Kernel.stub(:load)
        @maid = Maid.new
      end

      it 'sets the Maid instance' do
        expect(::Maid).to receive(:with_instance).with(@maid)
        @maid.load_rules
      end

      it 'gives an error on STDERR if there is a LoadError' do
        Kernel.stub(:load).and_raise(LoadError)
        expect(STDERR).to receive(:puts)
        @maid.load_rules
      end
    end

    describe '#rule' do
      before do
        @maid = Maid.new
      end

      it 'adds a rule to the list of rules' do
        expect(@maid.rules.length).to eq(0)

        @maid.rule('description') do
          'instructions'
        end

        expect(@maid.rules.length).to eq(1)
        expect(@maid.rules.first.description).to eq('description')
      end
    end

    describe '#follow_rules' do
      it 'follows each rule' do
        n = 3
        maid = Maid.new
        expect(@logger).to receive(:info).exactly(n).times
        rules = (1..n).map do |n|
          d = double("rule ##{ n }", :description => 'description')
          expect(d).to receive(:follow)
          d
        end
        maid.instance_eval { @rules = rules }

        maid.follow_rules
      end
    end

    describe '#cmd' do
      before do
        @maid = Maid.new
      end

      it 'reports `not-a-real-command` as not being a supported command' do
        expect(lambda { @maid.cmd('not-a-real-command arg1 arg2') }).to raise_error(NotImplementedError)
      end

      it 'should report `echo` as a real command' do
        expect(lambda { @maid.cmd('echo .') }).not_to raise_error
      end
    end
  end
end
