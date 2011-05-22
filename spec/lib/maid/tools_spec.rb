require 'spec_helper'

module Maid
  describe Tools do
    before :each do
      @home = File.expand_path('~')

      Maid.ancestors.should include(Tools)
      @maid = Maid.new
      FileUtils.stub!(:mv)
    end

    describe '#move' do
      before :each do
        @logger  = @maid.instance_eval { @logger }

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

    describe '#trash' do
      before :each do
        @trash_path = @maid.trash_path
        @path = '~/Downloads/foo.zip'
      end

      it 'should move the path to the trash' do
        @maid.should_receive(:move).with(@path, @trash_path)
        @maid.trash(@path)
      end

      it 'should use a safe path if the target exists' do
        Timecop.freeze(Time.parse('2011-05-22T16:53:52-04:00')) do
          File.stub!(:exist?).and_return(true)
          @maid.should_receive(:move).with(@path, "#{@trash_path}/foo.zip 2011-05-22-16-53-52")
          @maid.trash(@path)
        end
      end
    end

    describe '#dir' do
      it 'should delegate to Dir#[] with an expanded path' do
        Dir.should_receive(:[]).with("#@home/Downloads/*.zip")
        @maid.dir('~/Downloads/*.zip')
      end
    end

    describe '#find' do
      it 'should delegate to Find.find with an expanded path' do
        f = lambda { }
        Find.should_receive(:find).with("#@home/Downloads/foo.zip", &f)
        @maid.find('~/Downloads/foo.zip', &f)
      end
    end
  end
end
