# encoding: utf-8
require 'spec_helper'

module Maid
  # NOTE: Please use FakeFS instead of mocking and stubbing specific calls which happen to modify the filesystem.
  #
  # More info:
  #
  # * [FakeFS](https://github.com/defunkt/fakefs)
  describe Tools, :fakefs => true do
    before do
      @home = File.expand_path('~')
      @now = Time.now

      Maid.ancestors.should include(Tools)

      @logger = double('Logger').as_null_object
      @maid = Maid.new(:logger => @logger)

      # Prevent warnings from showing when testing deprecated methods:
      @maid.stub(:__deprecated_run_action__)

      # For safety, stub `cmd` to prevent running commands:
      @maid.stub(:cmd)
    end

    describe '#move' do
      before do
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

      it 'should handle multiple from paths' do
        second_src_file = @src_dir + (second_file_name = 'bar.zip')
        FileUtils.touch(second_src_file)
        src_files = [@src_file, second_src_file]

        @maid.move(src_files, @dst_dir)
        File.exist?(@dst_dir + @file_name).should be_true
        File.exist?(@dst_dir + second_file_name).should be_true
      end

      context 'given the destination directory does not exist' do
        before do
          FileUtils.rmdir(@dst_dir)
        end

        it 'does not overwrite when moving' do
          FileUtils.should_not_receive(:mv)
          @logger.should_receive(:warn).once

          another_file = "#@src_file.1"
          @maid.move([@src_file, another_file], @dst_dir)
        end
      end
    end

    describe '#rename' do
      before do
        @src_file = (@src_dir = '~/Source/') + (@file_name = 'foo.zip')
        FileUtils.mkdir_p(@src_dir)
        FileUtils.touch(@src_file)
        @expanded_src_name = "#@home/Source/foo.zip"

        @dst_name = '~/Destination/bar.zip'
        @expanded_dst_dir = "#@home/Destination/"
        @expanded_dst_name = "#@home/Destination/bar.zip"
      end

      it 'creates needed directories' do
        File.directory?(@expanded_dst_dir).should be_false
        @maid.rename(@src_file, @dst_name)
        File.directory?(@expanded_dst_dir).should be_true
      end

      it 'moves the file from the source to the destination' do
        File.exists?(@expanded_src_name).should be_true
        File.exists?(@expanded_dst_name).should be_false
        @maid.rename(@src_file, @dst_name)
        File.exists?(@expanded_src_name).should be_false
        File.exists?(@expanded_dst_name).should be_true
      end

      context 'given the target already exists' do
        before do
          FileUtils.mkdir_p(@expanded_dst_dir)
          FileUtils.touch(@expanded_dst_name)
        end

        it 'does not move' do
          @logger.should_receive(:warn)

          @maid.rename(@src_file, @dst_name)
        end
      end
    end

    describe '#trash' do
      before do
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
        @maid.stub(:disk_usage) { 1025 }
        @maid.trash(@src_file, :remove_over => 1.mb)
        File.exist?(@src_file).should_not be_true
        File.exist?(@trash_file).should_not be_true
      end

      it 'should trash files less then the remove option size' do
        @maid.stub(:disk_usage) { 1023 }
        @maid.trash(@src_file, :remove_over => 1.mb)
        File.exist?(@trash_file).should be_true
      end
    end

    describe '#remove' do
      before do
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
        second_src_file = "#@src_dir/bar.zip"
        FileUtils.touch(second_src_file)
        @src_files = [@src_file, second_src_file]

        @maid.remove(@src_files)
        File.exist?(@src_file).should be_false
        File.exist?(second_src_file).should be_false
      end
    end

    describe '#dir' do
      before do
        @file = (@dir = "#@home/Downloads") + '/foo.zip'
        FileUtils.mkdir_p(@dir)
      end

      it 'lists files in a directory' do
        FileUtils.touch(@file)
        @maid.dir('~/Downloads/*.zip').should == [@file]
      end

      it 'lists multiple files in alphabetical order' do
        # It doesn't occur with `FakeFS` as far as I can tell, but Ubuntu (and possibly OS X) can give the results out
        # of lexical order.  That makes using the `dry-run` output difficult to use.
        Dir.stub(:glob) { %w(/home/foo/b.zip /home/foo/a.zip /home/foo/c.zip) }
        @maid.dir('~/Downloads/*.zip').should == %w(/home/foo/a.zip /home/foo/b.zip /home/foo/c.zip)
      end

      context 'with multiple files' do
        before do
          @other_file = "#@dir/qux.tgz"
          FileUtils.touch(@file)
          FileUtils.touch(@other_file)
        end

        it 'list files in all provided globs' do
          @maid.dir(%w(~/Downloads/*.tgz ~/Downloads/*.zip)).should == [@file, @other_file]
        end

        it 'lists files when using regexp-like glob patterns' do
          @maid.dir('~/Downloads/*.{tgz,zip}').should == [@file, @other_file]
        end
      end

      context 'with multiple directories' do
        before do
          @other_file = "#@home/Desktop/bar.zip"
          FileUtils.touch(@file)
          FileUtils.mkdir_p(File.dirname(@other_file))
          FileUtils.touch(@other_file)
        end

        it 'lists files in directories when using regexp-like glob patterns' do
          @maid.dir('~/{Desktop,Downloads}/*.zip').should == [@other_file, @file]
        end

        it 'lists files in directories when using recursive glob patterns' do
          @maid.dir('~/**/*.zip').should == [@other_file, @file]
        end
      end
    end

    describe '#files' do
      before do
        @file = (@dir = "#@home/Downloads") + '/foo.zip'
        FileUtils.mkdir_p(@dir)
        FileUtils.mkdir(@dir + '/notfile')
      end

      it 'lists only files in a directory' do
        FileUtils.touch(@file)
        @maid.files('~/Downloads/*.zip').should == [@file]
      end

      it 'lists multiple files in alphabetical order' do
        # It doesn't occur with `FakeFS` as far as I can tell, but Ubuntu (and possibly OS X) can give the results out
        # of lexical order.  That makes using the `dry-run` output difficult to use.
        Dir.stub(:glob) { %w(/home/foo/b.zip /home/foo/a.zip /home/foo/c.zip) }
        @maid.dir('~/Downloads/*.zip').should == %w(/home/foo/a.zip /home/foo/b.zip /home/foo/c.zip)
      end

      context 'with multiple files' do
        before do
          @other_file = "#@dir/qux.tgz"
          FileUtils.touch(@file)
          FileUtils.touch(@other_file)
        end

        it 'list files in all provided globs' do
          @maid.dir(%w(~/Downloads/*.tgz ~/Downloads/*.zip)).should == [@file, @other_file]
        end

        it 'lists files when using regexp-like glob patterns' do
          @maid.dir('~/Downloads/*.{tgz,zip}').should == [@file, @other_file]
        end
      end

      context 'with multiple directories' do
        before do
          @other_file = "#@home/Desktop/bar.zip"
          FileUtils.touch(@file)
          FileUtils.mkdir_p(File.dirname(@other_file))
          FileUtils.mkdir(@home + '/Desktop/notfile')
          FileUtils.touch(@other_file)
        end

        it 'lists files in directories when using regexp-like glob patterns' do
          @maid.dir('~/{Desktop,Downloads}/*.zip').should == [@other_file, @file]
        end
      end
    end

    describe '#escape_glob' do
      it 'escapes characters that have special meanings in globs' do
        @maid.escape_glob('test [tmp]').should == 'test \\[tmp\\]'
      end
    end

    describe '#mkdir' do
      it 'should create a directory successfully' do
        @maid.mkdir('~/Downloads/Music/Pink.Floyd')
        File.exist?("#@home/Downloads/Music/Pink.Floyd").should be_true
      end

      it 'should log the creation of the directory' do
        @logger.should_receive(:info)
        @maid.mkdir('~/Downlaods/Music/Pink.Floyd')
      end

      it 'returns the path of the created directory' do
        @maid.mkdir('~/Reference/Foo').should == "#@home/Reference/Foo"
      end

      # FIXME: FakeFS doesn't seem to report `File.exist?` properly.  However, this has been tested manually.
      #
      #     it 'should respect the noop option' do
      #       @maid.mkdir('~/Downloads/Music/Pink.Floyd')
      #       File.exist?("#@home/Downloads/Music/Pink.Floyd").should be_false
      #     end
    end

    describe '#find' do
      before do
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
      before do
        Platform.stub(:osx?) { true }
      end

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
        entries = [double(:name => 'foo.exe'), double(:name => 'README.txt'), double(:name => 'subdir/anything.txt')]
        Zip::File.stub(:open).and_yield(entries)

        @maid.zipfile_contents('foo.zip').should == ['README.txt', 'foo.exe', 'subdir/anything.txt']
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
        Timecop.freeze(@now) do
          FileUtils.touch(File.expand_path(@path))
          @maid.created_at(@path).should == Time.now
        end
      end
    end

    describe '#accessed_at' do
      # FakeFS does not implement atime.
      it 'should give the last accessed time of the file' do
        File.should_receive(:atime).with("#@home/foo.zip").and_return(@now)
        @maid.accessed_at('~/foo.zip').should == @now
      end

      it 'should trigger deprecation warning when last_accessed is used, but still run' do
        File.should_receive(:atime).with("#@home/foo.zip").and_return(@now)
        @maid.should have_deprecated_method(:last_accessed)
        @maid.last_accessed('~/foo.zip').should == @now
      end
    end

    describe '#modified_at' do
      before do
        @path = '~/test.txt'
        FileUtils.touch(File.expand_path(@path))
      end

      it 'should give the modified time of the file' do
        Timecop.freeze(@now) do
          File.open(@path, 'w') { |f| f.write('Test') }
        end

        # use to_i to ignore milliseconds during test
        @maid.modified_at(@path).to_i.should == @now.to_i
      end
    end

    describe '#size_of' do
      before do
        @file = '~/foo.zip'
      end

      it 'should give the size of the file' do
        File.should_receive(:size).with(@file).and_return(42)
        @maid.size_of(@file).should == 42
      end
    end

    describe '#checksum_of' do
      before do
        @file = '~/test.txt'
      end

      it 'should return the checksum of the file' do
        File.should_receive(:read).with(@file).and_return('contents')
        @maid.checksum_of(@file).should == Digest::MD5.hexdigest('contents')
      end
    end

    describe '#git_piston' do
      it 'is deprecated' do
        @maid.should have_deprecated_method(:git_piston)
        @maid.git_piston('~/code/projectname')
      end

      it 'should pull and push the given git repository, logging the action' do
        @maid.should_receive(:cmd).with(%(cd #@home/code/projectname && git pull && git push 2>&1))
        @logger.should_receive(:info)
        @maid.git_piston('~/code/projectname')
      end
    end

    describe '#sync' do
      before do
        @src_dir = '~/Downloads/'
        @dst_dir = '~/Reference'
      end

      it 'should sync the expanded paths, retaining backslash' do
        @maid.should_receive(:cmd).with(%(rsync -a -u #@home/Downloads/ #@home/Reference 2>&1))
        @maid.sync(@src_dir, @dst_dir)
      end

      it 'should log the action' do
        @logger.should_receive(:info)
        @maid.sync(@src_dir, @dst_dir)
      end

      it 'should have no options' do
        @maid.should_receive(:cmd).with(%(rsync  #@home/Downloads/ #@home/Reference 2>&1))
        @maid.sync(@src_dir, @dst_dir, :archive => false, :update => false)
      end

      it 'should add all options' do
        @maid.should_receive(:cmd).with(%(rsync -a -v -u -m --exclude=.git --delete #@home/Downloads/ #@home/Reference 2>&1))
        @maid.sync(@src_dir, @dst_dir, :archive => true, :update => true, :delete => true, :verbose => true, :prune_empty => true, :exclude => '.git')
      end

      it 'should add multiple exlcude options' do
        @maid.
          should_receive(:cmd).
          with(%(rsync -a -u --exclude=.git --exclude=.rvmrc #@home/Downloads/ #@home/Reference 2>&1))
        @maid.sync(@src_dir, @dst_dir, :exclude => ['.git', '.rvmrc'])
      end

      it 'should add noop option' do
        @maid.file_options[:noop] = true
        @maid.should_receive(:cmd).with(%(rsync -a -u -n #@home/Downloads/ #@home/Reference 2>&1))
        @maid.sync(@src_dir, @dst_dir)
      end
    end
  end

  describe Tools, :fakefs => false do
    let(:file_fixtures_path) { File.expand_path(File.dirname(__FILE__) + '../../../fixtures/files/') }
    let(:file_fixtures_glob) { "#{ file_fixtures_path }/*" }
    let(:image_path) { File.join(file_fixtures_path, 'ruby.jpg') }
    let(:unknown_path) { File.join(file_fixtures_path, 'unknown.foo') }

    before do
      @logger = double('Logger').as_null_object
      @maid = Maid.new(:logger => @logger)
    end

    describe '#dupes_in' do
      it 'should list duplicate files in arrays' do
        dupes = @maid.dupes_in(file_fixtures_glob)
        dupes.first.should be_kind_of(Array)

        basenames = dupes.flatten.map { |p| File.basename(p) }
        basenames.should == %w(1.zip bar.zip foo.zip)
      end
    end

    describe '#verbose_dupes_in' do
      it 'should list all but the shortest-named dupe' do
        dupes = @maid.verbose_dupes_in(file_fixtures_glob)

        basenames = dupes.flatten.map { |p| File.basename(p) }
        basenames.should == %w(bar.zip foo.zip)
      end
    end

    describe '#newest_dupes_in' do
      it 'should list all but the shortest-named dupe' do
        oldest_path = "#{file_fixtures_path}/foo.zip"
        FileUtils.touch(oldest_path, :mtime => Time.new(1970, 1, 1))

        dupes = @maid.newest_dupes_in(file_fixtures_glob)

        basenames = dupes.flatten.map { |p| File.basename(p) }
        basenames.should == %w(bar.zip 1.zip)
      end
    end

    describe '#mime_type' do
      context 'given a JPEG image' do
        it 'reports "image/jpeg"' do
          @maid.mime_type(image_path).should == 'image/jpeg'
        end
      end

      context 'given an unknown type' do
        it 'returns nil' do
          @maid.mime_type(unknown_path).should be_nil
        end
      end
    end

    describe '#media_type' do
      context 'given a JPEG image' do
        it 'reports "image"' do
          @maid.media_type(image_path).should == 'image'
        end
      end

      context 'given an unknown type' do
        it 'returns nil' do
          @maid.media_type(unknown_path).should be_nil
        end
      end
    end

    describe '#where_content_type' do
      context 'given "image"' do
        it 'only lists the fixture JPEG' do
          matches = @maid.where_content_type(@maid.dir(file_fixtures_glob), 'image')

          matches.length.should == 1
          matches.first.should end_with('spec/fixtures/files/ruby.jpg')
        end
      end
    end
  end
end
