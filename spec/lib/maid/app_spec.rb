require 'spec_helper'
require 'stringio'

def capture_stdout
  out = StringIO.new
  $stdout = out
  yield
  out.string
ensure
  $stdout = STDOUT
end

def capture_stderr
  out = StringIO.new
  $stderr = out
  yield
  out.string
ensure
  $stderr = STDERR
end

module Maid
  describe App, '#clean' do

    before do
      @app = App.new
      @app.stub(:maid_options)
      @app.stub(:say)

      TrashMigration.stub(:needed?) { false }

      # NOTE: It's pretty important that this is stubbed, unless you want your rules to be run over and over when you test!
      @maid = double('Maid')
      @maid.stub(:clean)
      @maid.stub(:log_device)
      @maid.stub(:load_rules)
      Maid.stub(:new) { @maid }
    end

    it 'makes a new Maid with the options' do
      opts = { :foo => 'bar' }
      @app.stub(:maid_options).and_return(opts)
      expect(Maid).to receive(:new).with(opts).and_return(@maid)
      @app.clean
    end

    it 'cleans when --force is specified' do      
      expect(@maid).to receive(:clean)
      App.start(['clean', '--force'])
    end 

    it 'issues deprecation notice when called without option, but still clean' do
      expect(@maid).to receive(:clean).twice
      expect(capture_stderr { App.start(['clean']) }).to match(/deprecated/)
      expect(capture_stderr { App.start(['clean', '--silent']) }).to match(/deprecated/)
    end

    it 'is not silent if not given the --silent option' do
      expect(capture_stdout { App.start(['clean', '--force']) }).not_to eq('')
    end

    it 'is silent if given the --silent option' do
      # TODO: It might even make sense to wrap `maid.clean` in `capture_stdout { ... }`
      expect(capture_stdout { App.start(['clean', '--noop', '--silent']) }).to eq('')
      expect(capture_stdout { App.start(['clean', '--force', '--silent']) }).to eq('')
    end

    it 'complains about a MISSPELLED option' do
      expect(capture_stderr { App.start(['clean', '--slient']) }).to match(/Unknown/)
      expect(capture_stderr { App.start(['clean', '--noop', '--slient']) }).to match(/Unknown/)
    end

    it 'complains about an undefined task' do
      expect(capture_stderr { App.start(['rules.rb']) }).to match(/Could not find/)
    end
  end

  describe App, '#version' do
    before do
      @app = App.new
    end

    it 'prints out the gem version' do
      expect(@app).to receive(:say).with(VERSION)
      @app.version
    end

    it 'is mapped as --version' do
      expect(App.start(['--version'])).to eq(@app.version)
    end

    context 'with the "long" option' do
      before do
        # FIXME: This is ugly.  Maybe use `Maid.start(%w(version --long))` instead.

        # We can't simply stub `long?` because `options` is a frozen object.
        options = double('options', :long? => true)
        @app.options = options
      end

      it 'prints out the gem version' do
        ua = 'Maid/0.0.1'
        UserAgent.stub(:value) { ua }
        expect(@app).to receive(:say).with(ua)
        @app.version
      end
    end
  end

  describe App, '#maid_options' do
    before do
      @app = App.new
    end

    it 'logs to STDOUT for testing purposes when given noop' do
      opts = @app.maid_options('noop' => true)
      expect(opts[:file_options][:noop]).to be(true)
      expect(opts[:logger]).to be(false)
      expect(opts[:log_device]).to eq(STDOUT)
      expect(opts[:log_formatter].call(nil, nil, nil, 'hello')).to eq("hello\n")
    end

    it 'sets the rules path when given rules' do
      opts = @app.maid_options('rules' => 'maid_rules.rb')
      expect(opts[:rules_path]).to match(/maid_rules.rb$/)
    end
  end

  describe App, '#logs' do
    before do
      @maid = double('Maid')
      @maid.stub(:clean)
      @maid.stub(:log_device) { '/var/log/maid.log' }
      @maid.stub(:load_rules)
      Maid.stub(:new) { @maid }
    end

    describe 'prints out the log' do
      before do
        @log = "A maid log\nAnother log"
        @log_file = Tempfile.new('maid.log')
        @log_file.write(@log)
        @log_file.close

        @maid.stub(:log_device) { @log_file.path }
      end

      after do
        @log_file.unlink if !@log_file.nil?
      end

      it 'dumps the last log entries when invoked without an option' do
        expect(capture_stdout { App.start(['logs']) }).to eq("#{@log}\n")
      end

      it 'prints an error when log does not exist' do
        @maid.stub(:log_device) { '/maid/file-does-not-exist' }
        message = "Log file #{@maid.log_device} does not exist.\n"

        expect(capture_stderr { App.start(['logs']) }).to eq(message)
      end

      it 'does not tail when log does not exist' do
        @maid.stub(:log_device) { '/maid/file-does-not-exist' }
        message = "Log file #{@maid.log_device} does not exist.\n"

        expect(capture_stderr { App.start(['logs', '--tail']) }).to eq(message)
      end
    end

    it 'prints out the log path' do
      ['--path', '-p'].each do |option|
        expect(capture_stdout { App.start(['logs', option]) }).to eq("/var/log/maid.log\n")
      end
    end
  end
end
