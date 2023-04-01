require 'spec_helper'

module Maid
  describe Maid, fakefs: true do
    let(:logger) { instance_spy('Logger') }

    before do
      allow(Logger).to receive(:new).and_return(logger)
    end

    describe '.new' do
      it 'sets up a logger with the default path' do
        expect(Logger).to receive(:new).with(Maid::DEFAULTS[:log_device], anything, anything)
        Maid.new
      end

      it 'sets up a logger with the given path, when provided' do
        log_device = '/var/log/maid.log'
        expect(Logger).to receive(:new).with(log_device, anything, anything)
        Maid.new(log_device: log_device)
      end

      it 'rotates the log with the default settings' do
        expect(Logger).to receive(:new).with(anything, Maid::DEFAULTS[:log_shift_age],
                                             Maid::DEFAULTS[:log_shift_size],)
        Maid.new
      end

      it 'rotates the log with the given settings, when provided' do
        expect(Logger).to receive(:new).with(anything, 42, 1_000_000)
        Maid.new(log_shift_age: 42, log_shift_size: 1_000_000)
      end

      it 'makes the log directory in case it does not exist' do
        expect(File.exist?('/home/username/log')).to be false

        Maid.new(log_device: '/home/username/log/maid.log')

        expect(File.exist?('/home/username/log')).to be true
      end

      it 'takes a logger object during intialization' do
        allow(Logger).to receive(:new).and_call_original
        maid = Maid.new(logger: logger)
        expect(maid.logger).to eq(logger)
      end

      describe 'platform-specific behavior' do
        before do
          allow(Platform).to receive(:linux?)
          allow(Platform).to receive(:osx?)
          @home = File.expand_path('~')
        end

        context 'when running on Linux' do
          before do
            allow(Platform).to receive(:linux?).and_return(true)
            allow(XDG).to receive(:[]).with('DATA_HOME').and_return("#{@home}/.local/share")
          end

          it 'set the trash to the correct default path' do
            trash_path = "#{@home}/.local/share/Trash/files/"

            maid = Maid.new

            expect(maid.trash_path).to eq(trash_path)
          end
        end

        context 'when running on OS X' do
          before do
            allow(Platform).to receive(:osx?).and_return(true)
          end

          it 'sets the trash to the correct default path' do
            trash_path = "#{@home}/.Trash/"

            maid = Maid.new
            expect(maid.trash_path).to eq(trash_path)
          end
        end

        context 'when running on an unsupported platform' do
          it 'does not implement trashing files' do
            expect { Maid.new }.to raise_error(NotImplementedError)
          end
        end
      end

      it 'sets the trash to the given path, if provided' do
        trash_path = '/home/username/tmp/my_trash/'

        maid = Maid.new(trash_path: trash_path)

        expect(maid.trash_path).not_to be_nil
        expect(maid.trash_path).to eq(trash_path)
      end

      it 'sets the progname for the logger' do
        Maid.new

        expect(logger).to have_received(:progname=).with(Maid::DEFAULTS[:progname])
      end

      it 'sets the progname for the logger to the given name, if provided' do
        Maid.new(progname: 'Fran')

        expect(logger).to have_received(:progname=).with('Fran')
      end

      it 'sets the file options to the defaults' do
        expect(Maid.new.file_options).to eq(Maid::DEFAULTS[:file_options])
      end

      it 'sets the file options to the given options, if provided' do
        maid = Maid.new(file_options: { verbose: true })
        expect(maid.file_options).to eq(verbose: true)
      end

      it 'sets the rules path' do
        expect(Maid.new.rules_path).to eq(Maid::DEFAULTS[:rules_path])
      end

      it 'sets the rules pathto the given path, if provided' do
        maid = Maid.new(rules_path: 'Maidfile')
        expect(maid.rules_path).to eq('Maidfile')
      end

      it 'ignores nil options' do
        maid = Maid.new(rules_path: nil)
        expect(maid.rules_path).to eq(Maid::DEFAULTS[:rules_path])
      end
    end

    describe '#clean' do
      before do
        @maid = Maid.new
        allow(logger).to receive(:info)
      end

      it 'logs start and finish' do
        @maid.clean

        expect(logger).to have_received(:info).with('Started')
        expect(logger).to have_received(:info).with('Finished')
      end

      it 'follows the given rules' do
        expect(@maid).to receive(:follow_rules)
        @maid.clean
      end
    end

    describe '#load_rules' do
      context 'when there is no LoadError' do
        before do
          allow(Kernel).to receive(:load)
        end

        let(:maid) { Maid.new }

        it 'sets the Maid instance' do
          expect(::Maid).to receive(:with_instance).with(maid)
          maid.load_rules
        end
      end

      context 'when there is a LoadError' do
        let(:maid) { Maid.new }

        before do
          allow(Kernel).to receive(:load).and_raise(LoadError)
          allow(Logger).to receive(:warn)
        end

        it 'gives an error on STDERR if there is a LoadError' do
          maid.load_rules

          expect(logger).to have_received(:warn).once
        end
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

    describe '#watch' do
      before do
        allow(Listen).to receive(:to)
        allow(Listen).to receive(:start)
        FileUtils.mkdir_p('watch_dir')
        @maid = Maid.new
      end

      it 'adds a watch to the list of watches' do
        expect(@maid.watches.length).to eq(0)

        @maid.watch('watch_dir') do
          'instructions'
        end

        expect(@maid.watches.length).to eq(1)
        expect(@maid.watches.first.path).to eq(File.expand_path('watch_dir'))
      end

      # FIXME: Example is too long, shouldn't need the rubocop::disable
      it 'accepts a hash of options and passes them to Listen' do # rubocop:disable RSpec/ExampleLength
        hash = { some: :options }
        FileUtils.mkdir_p('some_dir')

        @maid.watch('some_dir', hash) do
          rule 'test' do
          end
        end

        listener = double('listener')

        expect(Listen).to receive(:to) do |dir, opts|
          expect(dir).to eq File.expand_path('some_dir')
          expect(opts).to eq(hash)
          listener
        end

        expect(listener).to receive(:start)

        @maid.watches.last.run
      end
    end

    describe '#repeat' do
      before do
        # This is necessary for Rufus to work properly, but since we're using
        # FakeFS, the fake filesystem is missing that file.
        FakeFS::FileSystem.clone('/usr/share/zoneinfo') if Platform.linux?
        # OSX is special and uses a symlink at /usr/share/zoneinfo which
        # confuses FakeFS.
        # Instead, we create the /usr/share/zoneinfo/ directory on the FakeFS
        # and copy the zoneinfo data from elsewhere on OSX.
        if Platform.osx?
          # Where the actual zoneinfo data is
          FakeFS::FileSystem.clone('/var/db/timezone/tz/2023b.1.0/zoneinfo')
          # Where we need it to be
          FileUtils.mkdir_p('/usr/share/zoneinfo/')
          FileUtils.cp('/var/db/timezone/tz/2023b.1.0/zoneinfo', '/usr/share/zoneinfo/')
        end

        @maid = Maid.new
      end

      it 'adds a repeat to the list of repeats' do
        expect(@maid.repeats.length).to eq(0)

        @maid.repeat('1s') do
          'instructions'
        end

        expect(@maid.repeats.length).to eq(1)
        expect(@maid.repeats.first.timestring).to eq('1s')
      end

      # FIXME: Example is too long, shouldn't need the rubocop::disable
      it 'accepts a hash of options and passes them to Rufus' do # rubocop:disable RSpec/ExampleLength
        scheduler = double('scheduler')
        expect(Rufus::Scheduler).to receive(:singleton).and_return(scheduler)

        hash = { some: :options }
        @maid.repeat('1s', hash) do
          rule 'test' do
          end
        end

        expect(scheduler).to receive(:repeat).with('1s', hash)

        @maid.repeats.last.run
      end
    end

    describe '#follow_rules' do
      # FIXME: Example is too long, shouldn't need the rubocop::disable
      it 'follows each rule' do # rubocop:disable RSpec/ExampleLength
        n = 3
        maid = Maid.new

        rules = (1..n).map do |i|
          d = double("rule ##{i}", description: 'description')
          expect(d).to receive(:follow)
          d
        end
        maid.instance_eval { @rules = rules }

        maid.follow_rules

        expect(logger).to have_received(:info).exactly(n).times
      end
    end

    describe '#cmd' do
      before do
        @maid = Maid.new
      end

      it 'reports `not-a-real-command` as not being a supported command' do
        expect { @maid.cmd('not-a-real-command arg1 arg2') }.to raise_error(NotImplementedError)
      end

      it 'reports `echo` as a real command' do
        expect { @maid.cmd('echo .') }.not_to raise_error
      end
    end
  end
end
