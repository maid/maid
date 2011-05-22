require 'spec_helper'

module Maid
  describe Tools do
    before :each do
      Maid.ancestors.should include(Tools)
      @maid = Maid.new
      FileUtils.stub!(:mv)
    end

    describe '.move' do
      before :each do
        @logger  = @maid.instance_eval { @logger }

        @home    = File.expand_path('~')
        @from    = '~/Downloads/foo.zip'
        @to      = '~/Reference/'
        @options = @maid.file_options
      end

      it 'should move expanded paths, passing file_options' do
        FileUtils.should_receive(:mv).with("#{@home}/Downloads/foo.zip", "#{@home}/Reference", @options)
        @maid.move('~/Downloads/foo.zip', '~/Reference/')
      end

      it 'should log the move' do
        @logger.should_receive(:info)
        @maid.move(@from, @to)
      end

      it 'should not move if the target already exists' do
        File.stub!(:exist?).and_return(true)
        FileUtils.should_not_receive(:mv)
        @logger.should_receive(:warn)

        @maid.move(@from, @to)
      end
    end
  end
end
