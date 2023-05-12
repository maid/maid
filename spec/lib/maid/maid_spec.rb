require 'spec_helper'

module Maid
  describe Maid do
    let(:logger) { class_spy('Maid::Logger') }
    let(:logfile) { '/tmp/maid-specs/test.log' }
    let(:rules_file) { File.expand_path(File.join(File.dirname(__dir__), '../../fixtures/files/test_rules.rb')) }
    let(:test_defaults) { Maid::DEFAULTS.merge({ log_device: logfile, rules_path: rules_file }) }

    before do
      # Avoid FakeFS error when the logfile doesn't already exist.
      FileUtils.mkdir_p(File.dirname(logfile))
      FileUtils.touch(logfile)
    end

    after do
      # Cleanup afterwards
      FileUtils.rm_rf(File.dirname(logfile))
    end

    describe '.new' do
      context 'with the default options' do
        before { Maid.new(**test_defaults, logger: logger) }

        it 'sets up a logger with the default path' do
          expect(logger).to have_received(:new).with(device: test_defaults[:log_device])
        end
      end

      context 'with a custom logfile path' do
        let(:device) { '/tmp/maid-specs/overridden-maid.log' }

        before { Maid.new(log_device: device, logger: logger) }

        it 'sets up a logger with the given path, when provided' do
          expect(logger).to have_received(:new).with(device: device)
        end
      end

      context 'with a custom logger' do
        let(:maid) { Maid.new(logger: logger) }

        it 'uses it' do
          expect(maid.logger).to eq(logger)
        end
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

      context 'with a custom trash path' do
        let(:trash_path) { '/tmp/my_trash/' }
        let(:maid) { Maid.new(log_device: test_defaults[:log_device], trash_path: trash_path) }

        it 'sets the trash to the given path' do
          expect(maid.trash_path).not_to be_nil
          expect(maid.trash_path).to eq(trash_path)
        end
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
      let(:maid) { Maid.new(**test_defaults) }

      before do
        # Create the files that the test rules will impact
        FileUtils.mkdir_p('/tmp/maid-specs')
        FileUtils.touch('/tmp/maid-specs/perfect_man')

        maid.load_rules
        maid.clean
      end

      after do
        FileUtils.rm_rf('/tmp/maid-specs')
      end

      it 'logs start' do
        expect(File.read(logfile)).to match(/Started/)
      end

      it 'logs finish' do
        expect(File.read(logfile)).to match(/Finished/)
      end

      it 'follows the given rules' do
        expect(File.exist?('/tmp/maid-specs/perfect_man')).to be false
        expect(File.exist?('/tmp/maid-specs/buffalo_fuzz')).to be true
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
        let(:maid) { Maid.new(**test_defaults) }

        before do
          allow(Kernel).to receive(:load).and_raise(LoadError)
        end

        it 'gives an error on STDERR if there is a LoadError' do
          maid.load_rules

          expect(File.read(logfile)).to match(/LoadError/)
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
      it 'accepts a hash of options and passes them to Listen' do
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

      context('with a non-existent directory') do
        let(:maid) { Maid.new(**test_defaults) }

        it 'raises with an intelligible message' do
          expect { maid.watch('/doesnt_exist/') }.to raise_error(/file.*exist/)
        end

        it 'logs an intelligible message' do
          begin
            maid.watch('/doesnt_exist')
            # Suppressing the exception is fine, because we just want to test
            # that the message is logged when it throws and the test above
            # checks that the exception is raised.
          rescue StandardError
          end

          expect(File.read(logfile)).to match(/file.*exist/)
        end
      end
    end

    describe '#repeat', fake_zoneinfo: false do
      before do
        # Avoid FakeFS error when the logfile doesn't already exist.
        FileUtils.mkdir_p(File.dirname(logfile))
        FileUtils.touch(logfile)

        @maid = Maid.new(log_device: logfile)
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
      it 'accepts a hash of options and passes them to Rufus' do
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
      let(:maid) { Maid.new(**test_defaults) }

      it 'follows each rule' do
        # FIXME: This should run in a before and rules should be a let, but it
        # fails when arranged that way.
        rules = [spy(Rule), spy(Rule), spy(Rule)]
        maid.instance_eval { @rules = rules }
        maid.follow_rules

        expect(rules).to all(have_received(:follow).once)
      end
    end

    describe '#cmd' do
      before do
        # Avoid FakeFS bug
        FileUtils.mkdir_p(File.dirname(logfile))
        FileUtils.touch(logfile)

        @maid = Maid.new(log_device: logfile)
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
