require 'spec_helper'

module Maid
  # NOTE: Please use FakeFS instead of mocking and stubbing specific calls which happen to modify the filesystem.
  #
  # More info:
  #
  # * [FakeFS](https://github.com/defunkt/fakefs)
  describe Tools, :fakefs => true do
    before :each do
      @home = File.expand_path('~')

      Maid.ancestors.should include(Tools)

      # Due to issues with log creation prior to setting log below, use an existing file.
      @maid = Maid.new(:log_device => STDOUT)

      # FIXME: Maid should really take the logger directly, rather than the device.
      logger = mock('Logger', :info => nil, :warn => nil)
      @maid.instance_eval { @logger = logger }
      @logger = logger

      # For safety, stub `cmd` to prevent running commands:
      @maid.stub(:cmd)
    end

    describe '#move' do
      before :each do
        @src_file = (@src_dir = '~/Source/') + (@file_name = 'foo.zip')
        FileUtils.mkdir_p(@src_dir)
        FileUtils.touch(@src_file)
        FileUtils.mkdir_p(@dst_dir = '~/Destination/')
      end

      it 'should move expanded paths, passing file_options' do
        @maid.move(@src_file, @dst_dir)
        File.exists?(@dst_dir + @file_name).should be_true
      end

      it 'should log the move' do
        @logger.should_receive(:info)
        @maid.move(@src_file, @dst_dir)
      end

      it 'should not move if the target already exists' do
        FileUtils.touch(@dst_dir + @file_name)
        @logger.should_receive(:warn)

        @maid.move(@src_file, @dst_dir)
      end

      it 'should handle multiple from paths' do
        second_src_file = @src_dir + (second_file_name = 'bar.zip')
        FileUtils.touch(second_src_file)
        src_files = [@src_file, second_src_file]

        @maid.move(src_files, @dst_dir)
        File.exist?(@dst_dir + @file_name).should be_true
        File.exist?(@dst_dir + second_file_name).should be_true
      end
    end

    describe '#trash' do
      before :each do
        @trash_path = @maid.trash_path
        @src_file = (@src_dir = '~/Source/') + (@file_name = 'foo.zip')
        FileUtils.mkdir_p(@src_dir)
        FileUtils.touch(@src_file)

        @trash_file = File.join(@trash_path, @file_name)
      end

      it 'should move the path to the trash' do
        @maid.trash(@src_file)
        File.exist?(@trash_file).should be_true
      end

      it 'should use a safe path if the target exists' do
        # Without an offset, ISO8601 parses to local time, which is what we want here.
        Timecop.freeze(Time.parse('2011-05-22T16:53:52')) do
          FileUtils.touch(@trash_file)
          @maid.trash(@src_file)
          new_trash_file = File.join(@trash_path, @file_name + ' 2011-05-22-16-53-52')
          File.exist?(new_trash_file).should be_true
        end
      end

      it 'should handle multiple paths' do
        second_src_file = @src_dir + (second_file_name = 'bar.zip')
        FileUtils.touch(second_src_file)
        @src_files = [@src_file, second_src_file]
        @maid.trash(@src_files)

        second_trash_file = File.join(@trash_path, second_file_name)
        File.exist?(@trash_file).should be_true
        File.exist?(second_trash_file).should be_true
      end

      it 'should remove files greater then the remove option size' do
        @maid.stub!(:disk_usage).and_return(1025)
        @maid.trash(@src_file, :remove_over => 1.mb)
        File.exist?(@src_file).should_not be_true
        File.exist?(@trash_file).should_not be_true
      end

      it 'should trash files less then the remove option size' do
        @maid.stub!(:disk_usage).and_return(1023)
        @maid.trash(@src_file, :remove_over => 1.mb)
        File.exist?(@trash_file).should be_true
      end
    end

    describe '#remove' do
      before :each do
        @src_file = (@src_dir = '~/Source/') + (@file_name = 'foo.zip')
        FileUtils.mkdir_p(@src_dir)
        FileUtils.touch(@src_file)
        @src_file_expand_path = File.expand_path(@src_file)
        @options = @maid.file_options
      end

      it 'should remove expanded paths, passing options' do
        @maid.remove(@src_file)
        File.exist?(@src_file).should be_false
      end

      it 'should log the remove' do
        @logger.should_receive(:info)
        @maid.remove(@src_file)
      end

      it 'should set the secure option' do
        @options = @options.merge(:secure => true)
        FileUtils.should_receive(:rm_r).with(@src_file_expand_path, @options)
        @maid.remove(@src_file, :secure => true)
      end

      it 'should set the force option' do
        @options = @options.merge(:force => true)
        FileUtils.should_receive(:rm_r).with(@src_file_expand_path, @options)
        @maid.remove(@src_file, :force => true)
      end

      it 'should handle multiple paths' do
        second_src_file = @src_dir + (second_file_name = 'bar.zip')
        FileUtils.touch(second_src_file)
        @src_files = [@src_file, second_src_file]

        @maid.remove(@src_files)
        File.exist?(@src_file).should be_false
        File.exist?(second_src_file).should be_false
      end
    end

    describe '#dir' do
      before :each do
        @file = (dir = "#@home/Downloads/") + 'foo.zip'
        FileUtils.mkdir_p(dir)
      end

      it 'lists files in a directory' do
        FileUtils.touch(@file)
        @maid.dir('~/Downloads/*.zip').should == [@file]
      end
    end

    describe '#find' do
      before :each do
        @file = (@dir = '~/Source/') + (@file_name = 'foo.zip')
        FileUtils.mkdir_p(@dir)
        FileUtils.touch(@file)
        @dir_expand_path = File.expand_path(@dir)
        @file_expand_path = File.expand_path(@file)
      end

      it 'should delegate to Find.find with an expanded path' do
        f = lambda { }
        Find.should_receive(:find).with(@file_expand_path, &f)
        @maid.find(@file, &f)
      end

      it "should return an array of all the files' names when no block is given" do
        @maid.find(@dir).should == [@dir_expand_path, @file_expand_path]
      end
    end

    describe '#locate' do
      it 'should locate a file by name' do
        @maid.should_receive(:cmd).and_return("/a/foo.zip\n/b/foo.zip\n")
        @maid.locate('foo.zip').should == ['/a/foo.zip', '/b/foo.zip']
      end
    end

    describe '#downloaded_from' do
      it 'should determine the download site' do
        @maid.should_receive(:cmd).and_return(%((\n    "http://www.site.com/foo.zip",\n"http://www.site.com/"\n)))
        @maid.downloaded_from('foo.zip').should == ['http://www.site.com/foo.zip', 'http://www.site.com/']
      end
    end

    describe '#duration_s' do
      it 'should determine audio length' do
        @maid.should_receive(:cmd).and_return('235.705')
        @maid.duration_s('foo.mp3').should == 235.705
      end
    end

    describe '#zipfile_contents' do
      it 'should inspect the contents of a .zip file' do
        @maid.should_receive(:cmd).and_return("foo/foo.exe\nfoo/README.txt\n")
        @maid.zipfile_contents('foo.zip').should == ['foo/foo.exe', 'foo/README.txt']
      end
    end

    describe '#disk_usage' do
      it 'should give the disk usage of a file' do
        @maid.should_receive(:cmd).and_return('136     foo.zip')
        @maid.disk_usage('foo.zip').should == 136
      end

      context 'when the file does not exist' do
        it 'raises an error' do
          @maid.should_receive(:cmd).and_return('du: cannot access `foo.zip\': No such file or directory')
          lambda { @maid.disk_usage('foo.zip') }.should raise_error(RuntimeError)
        end
      end
    end

    describe '#created_at' do
      before do
        @path = "~/test.txt"
      end
      it 'should give the created time of the file' do
        time = Time.now
        Timecop.freeze(time) do
          FileUtils.touch(File.expand_path(@path))
        end
        @maid.created_at(@path).should == time
      end
    end

    describe '#accessed_at' do
      # FakeFS does not implement atime.
      it 'should give the last accessed time of the file' do
        time = Time.now
        File.should_receive(:atime).with("#@home/foo.zip").and_return(time)
        @maid.accessed_at('~/foo.zip').should == time
      end
      it 'should trigger deprecation warning when last_accessed is used, but still run' do
        time = Time.now
        File.should_receive(:atime).with("#@home/foo.zip").and_return(time)
        @logger.should_receive(:warning)
        @maid.last_accessed('~/foo.zip').should == time
      end
    end

    describe '#modified_at' do
      before do
        @path = "~/test.txt"
        FileUtils.touch(File.expand_path(@path))
      end
      it 'should give the modified time of the file' do
        time = Time.now
        Timecop.freeze(time) do
          File.open(@path, 'w') {|f| f.write('Test') }
        end
        # use to_i to ignore milliseconds during test
        @maid.modified_at(@path).to_i.should == time.to_i
      end
    end

    describe '#git_piston' do
      it 'should pull and push the given git repository, logging the action' do
        @maid.should_receive(:cmd).with(%(cd "#@home/code/projectname" && git pull && git push 2>&1))
        @logger.should_receive(:info)
        @maid.git_piston('~/code/projectname')
      end
    end

    describe '#sync' do
      before :each do
        @src_dir = '~/Downloads/'
        @dst_dir = '~/Reference'
      end

      it 'should sync the expanded paths, retaining backslash' do
        @maid.should_receive(:cmd).with(%(rsync -a -u "#@home/Downloads/" "#@home/Reference" 2>&1))
        @maid.sync(@src_dir, @dst_dir)
      end

      it 'should log the action' do
        @logger.should_receive(:info)
        @maid.sync(@src_dir, @dst_dir)
      end

      it 'should have no options' do
        @maid.should_receive(:cmd).with(%(rsync  "#@home/Downloads/" "#@home/Reference" 2>&1))
        @maid.sync(@src_dir, @dst_dir, :archive => false, :update => false)
      end

      it 'should add all options' do
        @maid.should_receive(:cmd).with(%(rsync -a -v -u -m --exclude=".git" --delete "#@home/Downloads/" "#@home/Reference" 2>&1))
        @maid.sync(@src_dir, @dst_dir, :archive => true, :update => true, :delete => true, :verbose => true, :prune_empty => true, :exclude => '.git')
      end

      it 'should add multiple exlcude options' do
        @maid.should_receive(:cmd).with(%(rsync -a -u --exclude=".git" --exclude=".rvmrc" "#@home/Downloads/" "#@home/Reference" 2>&1))
        @maid.sync(@src_dir, @dst_dir, :exclude => ['.git', '.rvmrc'])
      end

      it 'should add noop option' do
        @maid.file_options[:noop] = true
        @maid.should_receive(:cmd).with(%(rsync -a -u -n "#@home/Downloads/" "#@home/Reference" 2>&1))
        @maid.sync(@src_dir, @dst_dir)
      end
    end
  end
end
