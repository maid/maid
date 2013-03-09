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
      @app.stub!(:maid_options)
      @app.stub!(:say)

      TrashMigration.stub(:needed?) { false }

      # NOTE: It's pretty important that this is stubbed, unless you want your rules to be run over and over when you test!
      @maid = mock('Maid')
      @maid.stub!(:clean)
      @maid.stub!(:log_device)
      @maid.stub!(:load_rules)
      Maid.stub!(:new).and_return(@maid)
    end

    it 'should make a new Maid with the options' do
      opts = { :foo => 'bar' }
      @app.stub!(:maid_options).and_return(opts)
      Maid.should_receive(:new).with(opts).and_return(@maid)
      @app.clean
    end

    it 'should clean when --execute is specified' do      
      @maid.should_receive(:clean)
      App.start(['clean', '--execute'])
    end 

    it 'should not clean when --noop is specified' do
      @maid.should_not_receive(:clean)
      App.start(['clean', '--noop'])
    end

    it 'should issue deprecation notice when called without option' do
      capture_stdout { App.start(['clean']) }.string.should match(/deprecated/)
      capture_stdout { App.start(['clean', '--silent']) }.string.should match(/deprecated/)
    end

    it 'should not be silent if not given the --silent option' do
      capture_stdout { App.start(['clean', '--execute']) }.string.should_not == ''
    end

    it 'should be silent if given the --silent option' do
      # TODO: It might even make sense to wrap `maid.clean` in `capture_stdout { ... }`
      capture_stdout { App.start(['clean', '--noop', '--silent']) }.string.should == ''
      capture_stdout { App.start(['clean', '--execute', '--silent']) }.string.should == ''
    end

    it 'should complain about a MISSPELLED option' do
      capture_stderr { App.start(['clean', '--slient']) }.string.should match(/Unknown/)
      capture_stderr { App.start(['clean', '--noop', '--slient']) }.string.should match(/Unknown/)
    end

    it 'should complain about an undefined task' do
      capture_stderr { App.start(['rules.rb']) }.string.should match(/Could not find/)
    end
  end

  describe App, '#version' do
    before do
      @app = App.new
    end

    it 'should print out the gem version' do
      @app.should_receive(:say).with(VERSION)
      @app.version
    end

    it 'is mapped as --version' do
      App.start(['--version']).should == @app.version
    end

    context 'with the "long" option' do
      before do
        # FIXME: This is ugly.  Maybe use `Maid.start(%w(version --long))` instead.

        # We can't simply stub `long?` because `options` is a frozen object.
        options = mock('options', :long? => true)
        @app.options = options
      end

      it 'should print out the gem version' do
        ua = 'Maid/0.0.1'
        UserAgent.stub(:value) { ua }
        @app.should_receive(:say).with(ua)
        @app.version
      end
    end
  end

  describe App, '#maid_options' do
    before do
      @app = App.new
    end

    it 'should log to STDOUT for testing purposes when given noop' do
      opts = @app.maid_options('noop' => true)
      opts[:file_options][:noop].should be_true
      opts[:logger].should be_false
      opts[:log_device].should == STDOUT
      opts[:log_formatter].call(nil, nil, nil, 'hello').should == "hello\n"
    end

    it 'should set the rules path when given rules' do
      opts = @app.maid_options('rules' => 'maid_rules.rb')
      opts[:rules_path].should match(/maid_rules.rb$/)
    end
  end
end
