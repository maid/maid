require 'spec_helper'
require 'stringio'

module Maid
  describe App, '#clean' do
    def capture_stdout
      out = StringIO.new
      $stdout = out
      yield
      return out
    ensure
      $stdout = STDOUT
    end

    def capture_stderr
      out = StringIO.new
      $stderr = out
      yield
      return out
    ensure
      $stderr = STDERR
    end

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
      expect(capture_stderr { App.start(['clean']) }.string).to match(/deprecated/)
      expect(capture_stderr { App.start(['clean', '--silent']) }.string).to match(/deprecated/)
    end

    it 'is not silent if not given the --silent option' do
      expect(capture_stdout { App.start(['clean', '--force']) }.string).not_to eq('')
    end

    it 'is silent if given the --silent option' do
      # TODO: It might even make sense to wrap `maid.clean` in `capture_stdout { ... }`
      expect(capture_stdout { App.start(['clean', '--noop', '--silent']) }.string).to eq('')
      expect(capture_stdout { App.start(['clean', '--force', '--silent']) }.string).to eq('')
    end

    it 'complains about a MISSPELLED option' do
      expect(capture_stderr { App.start(['clean', '--slient']) }.string).to match(/Unknown/)
      expect(capture_stderr { App.start(['clean', '--noop', '--slient']) }.string).to match(/Unknown/)
    end

    it 'complains about an undefined task' do
      expect(capture_stderr { App.start(['rules.rb']) }.string).to match(/Could not find/)
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
end
