require 'spec_helper'

module Maid
  describe App, '#clean' do
    before :each do
      @app = App.new
      @app.stub!(:maid_options)
      @app.stub!(:say)

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
      opts = @app.maid_options('rules' => 'Maidfile')
      opts[:rules_path].should == 'Maidfile'
    end
  end
end
