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

    before :each do
      @app = App.new
      @app.stub!(:maid_options)
      @app.stub!(:say)

      # NOTE It's pretty important that this is stubbed, unless you want your rules to be run over and over when you test!
      @maid = mock('Maid')
      @maid.stub!(:clean)
      @maid.stub!(:log_path)
      Maid.stub!(:new).and_return(@maid)
    end

    it 'should make a new Maid with the options' do
      opts = {:foo => 'bar'}
      @app.stub!(:maid_options).and_return(opts)
      Maid.should_receive(:new).with(opts).and_return(@maid)
      @app.clean
    end

    it 'should tell the Maid to clean' do
      @maid.should_receive(:clean)
      @app.clean
    end

    it 'should be silent if given the --silent option' do
      # TODO It might even make sense to wrap "maid.clean" in capture_stdout { }...
      capture_stdout { App.start(['clean', '--silent']) }.string.should == ''
    end
  end

  describe App, '#version' do
    it 'should print out the gem version' do
      app = App.new
      app.should_receive(:say).with(VERSION)
      app.version
    end
  end

  describe App, '#maid_options' do
    before :each do
      @app = App.new
    end

    it 'should log to STDOUT for testing purposes when given noop' do
      opts = @app.maid_options('noop' => true)
      opts[:file_options][:noop].should be_true
      opts[:log_path].should == STDOUT
      opts[:log_formatter].call(nil, nil, nil, 'hello').should == "hello\n"
    end

    it 'should set the rules path when given rules' do
      opts = @app.maid_options('rules' => 'maid_rules.rb')
      opts[:rules_path].should match(/maid_rules.rb$/)
    end
  end
end
