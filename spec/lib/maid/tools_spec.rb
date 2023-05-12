require 'spec_helper'

module Maid
  # NOTE: FakeFS is disabled intentionally, because it causes weird and subtle
  # issues that are hard to debug. See https://github.com/maid/maid/issues/315
  # FIXME: Split test suite into smaller files, likely one file per described
  # method.
  # FIXME: Replace *all* occurences of writing to `~/` in favour or `/tmp/`.
  # FIXME: Fix all the RSpec/MultipleMemoizeHelpers issues in Rubocop.
  describe Tools, fakefs: false do
    let(:filefixtures_path) { File.expand_path(File.dirname(__FILE__) + '../../../fixtures/files/') }
    let(:filefixtures_glob) { "#{filefixtures_path}/*" }
    let(:image_path) { File.join(filefixtures_path, 'ruby.jpg') }
    let(:unknown_path) { File.join(filefixtures_path, 'unknown.foo') }
    let(:test_basedir) { '/tmp/maid-specs' }
    let(:logfile) { "#{test_basedir}/test.log" }
    let(:maid) { Maid.new({ log_device: logfile }) }

    before do
      FileUtils.mkdir_p(File.dirname(logfile))

      @home = File.expand_path('~')
      @now = Time.now

      expect(Maid.ancestors).to include(Tools)

      # FIXME: Keeping the double to avoid a large refactor for now, but this
      # probably isn't necessary anymore.
      @logger = double('::Logger').as_null_object
      @maid = Maid.new(logger: @logger)

      # Prevent warnings from showing when testing deprecated methods:
      allow(@maid).to receive(:__deprecated_run_action__)

      # For safety, stub `cmd` to prevent running commands:
      allow(@maid).to receive(:cmd)
    end

    after do
      # Ensure each test has a fresh logfile
      FileUtils.rm_rf(File.dirname(logfile))
    end

    describe '#move' do
      before do
        @src_dir = File.join(test_basedir, 'Source')
        @filename = 'foo.zip'
        @src_file = File.join(@src_dir, @filename)
        @dst_dir = File.join(test_basedir, 'Destination')
        FileUtils.mkdir_p(File.expand_path(@src_dir))
        FileUtils.touch(File.expand_path(@src_file))
        FileUtils.mkdir_p(File.expand_path(@dst_dir))
      end

      it 'moves expanded paths, passing file_options' do
        dest_file = File.expand_path(File.join(@dst_dir, @filename))

        @maid.move(@src_file, @dst_dir)
        expect(File.exist?(dest_file)).to be(true)
      end

      it 'logs the move' do
        expect(@logger).to receive(:info)
        @maid.move(@src_file, @dst_dir)
      end

      # FIXME: Example is too long, shouldn't need the rubocop::disable
      it 'handles multiple from paths' do # rubocop:disable RSpec/ExampleLength
        second_filename = 'bar.zip'
        second_src_file = File.join(@src_dir, second_filename)
        FileUtils.touch(File.expand_path(second_src_file))
        src_files = [@src_file, second_src_file]
        dst_file = File.expand_path(File.join(@dst_dir, @filename))
        second_dst_file = File.expand_path(File.join(@dst_dir, second_filename))

        @maid.move(src_files, @dst_dir)
        expect(File.exist?(dst_file)).to be(true)
        expect(File.exist?(second_dst_file)).to be(true)
      end

      context 'given the destination directory does not exist' do
        let(:src_file) { File.join(test_basedir, 'test_file') }
        let(:dst_dir) { File.join(test_basedir, 'dest') }
        let(:dst_file) { File.join(dst_dir, File.basename(src_file)) }

        before do
          FileUtils.mkdir_p(File.dirname(src_file))
          FileUtils.touch(src_file)
          FileUtils.mkdir_p(dst_dir)
          FileUtils.rmdir(dst_dir)
          FileUtils.rm_rf(logfile)

          maid.move(src_file, dst_dir)
        end

        after do
          FileUtils.rm_rf([File.dirname(src_file), File.dirname(dst_file)])
        end

        it "doesn't move the file" do
          expect(File.exist?(dst_file)).to be false
        end

        it 'logs a warning about it' do
          expect(File.read(logfile)).to match(/skipping move.*#{File.dirname(dst_file)}.*not.*directory/)
        end
      end

      context 'when the destination file already exists' do
        let(:src_file) { File.join(test_basedir, 'test_file') }
        let(:dst_dir) { File.join(test_basedir, 'dest') }
        let(:dst_file) { File.join(dst_dir, File.basename(src_file)) }

        before do
          FileUtils.mkdir_p(File.dirname(src_file))
          FileUtils.mkdir_p(dst_dir)
          FileUtils.touch(src_file)
          # Necessary to have different mtimes, they're identical otherwise
          sleep 0.05
          FileUtils.touch(dst_file)
        end

        after do
          FileUtils.rm_rf([File.dirname(src_file), File.dirname(dst_file)])
        end

        context 'by default' do
          let!(:original_mtime) { File.stat(dst_file).mtime }

          before do
            FileUtils.rm_rf(logfile)

            maid.move(src_file, dst_dir)
          end

          it 'logs an info message' do
            expect(File.read(logfile)).to match(/INFO.*already/)
            expect(File.read(logfile)).to match(/INFO.*anyway/)
            expect(File.read(logfile)).not_to match(/INFO.*skipping/)
          end

          it 'overwrites destination' do
            expect(File.stat(dst_file).mtime.freeze).not_to eq(original_mtime)
          end
        end

        context 'when clobber: false' do
          let!(:original_mtime) { File.stat(dst_file).mtime }

          before do
            FileUtils.rm_rf(logfile)

            maid.move(src_file, dst_dir, clobber: false)
          end

          it 'logs an info message' do
            expect(File.read(logfile)).not_to match(/INFO.*anyway/)
            expect(File.read(logfile)).to match(/INFO.*skipping/)
          end

          it "doesn't overwrite the destination file" do
            expect(File.stat(dst_file).mtime).to eq(original_mtime)
          end
        end
      end
    end

    describe '#rename' do
      let(:src_file) { File.join(test_basedir, 'test_file') }
      let(:dst_dir) { File.join(test_basedir, 'dest') }
      let(:dst_file) { File.join(dst_dir, 'dest_test_file') }

      before do
        FileUtils.mkdir_p(File.dirname(src_file))
        FileUtils.touch(src_file)
      end

      after do
        FileUtils.rm_rf([File.dirname(src_file), File.dirname(dst_file)])
      end

      it 'creates needed directories' do
        expect(File.directory?(dst_dir)).to be(false)

        maid.rename(src_file, dst_file)

        expect(File.directory?(dst_dir)).to be(true)
      end

      it 'moves the file from the source to the destination' do
        expect(File.exist?(src_file)).to be(true)
        expect(File.exist?(dst_file)).to be(false)

        maid.rename(src_file, dst_file)

        expect(File.exist?(src_file)).to be(false)
        expect(File.exist?(dst_file)).to be(true)
      end

      context 'given the target already exists' do
        let(:src_file) { File.join(test_basedir, 'test_file') }
        let(:dst_dir) { File.join(test_basedir, 'dest') }
        let(:dst_file) { File.join(dst_dir, 'dest_test_file') }

        before do
          FileUtils.mkdir_p(File.dirname(src_file))
          FileUtils.touch(src_file)
          # Necessary to have different mtimes, they're identical otherwise
          sleep 0.05
          FileUtils.mkdir_p(File.dirname(dst_file))
          FileUtils.touch(dst_file)

          maid.rename(src_file, dst_file)
        end

        after do
          FileUtils.rm_rf([File.dirname(src_file), File.dirname(dst_file)])
        end

        it 'does not move' do
          expect(File.stat(src_file).mtime).not_to eq(File.stat(dst_file).mtime)
        end

        it 'logs a message' do
          expect(File.read(logfile)).to match(/WARN.*skipping rename.*overwrite/)
        end
      end
    end

    describe '#trash' do
      let(:src_file) { File.join(test_basedir, 'test_file') }
      let(:trash_file) { File.join(maid.trash_path, File.basename(src_file)) }
      let(:dst_dir) { File.join(test_basedir, 'dest') }
      let(:dst_file) { File.join(dst_dir, File.basename(src_file)) }

      before do
        FileUtils.mkdir_p(File.dirname(src_file))
        FileUtils.touch(src_file)
      end

      after do
        FileUtils.rm_rf([File.dirname(src_file), File.dirname(dst_file)])
      end

      it 'moves the path to the trash' do
        maid.trash(src_file)
        expect(File.exist?(File.join(maid.trash_path, File.basename(src_file)))).to be(true)
      end

      it 'uses a safe path if the target exists' do
        # Without an offset, ISO8601 parses to local time, which is what we want here.
        Timecop.freeze(Time.parse('2011-05-22T16:53:52')) do
          FileUtils.touch(trash_file)
          maid.trash(src_file)
          new_trash_file = File.join(maid.trash_path, File.basename(src_file) + ' 2011-05-22-16-53-52')

          expect(File.exist?(new_trash_file)).to be(true)
        end
      end

      context 'with multiple files' do
        let(:src_file2) { "#{src_file}_2" }

        before do
          FileUtils.touch(File.expand_path(src_file2))
          maid.trash([src_file, src_file2])
        end

        after do
          FileUtils.rm_rf([src_file, src_file2])
          trash_file = File.join(maid.trash_path, File.basename(src_file))
          trash_file2 = File.join(maid.trash_path, File.basename(src_file2))
          FileUtils.rm_rf([trash_file, trash_file2])
        end

        it 'deletes all files' do
          expect(File.exist?(File.join(maid.trash_path, File.basename(src_file)))).to be(true)
          expect(File.exist?(File.join(maid.trash_path, File.basename(src_file2)))).to be(true)
        end
      end

      context 'when given the `:remove_over` option' do
        context 'with files larger than :remove_over' do
          let(:trash_file) { File.join(maid.trash_path, File.basename(src_file)) }

          before do
            allow(maid).to receive(:disk_usage).and_return(1025)

            maid.trash(src_file, remove_over: 1.mb)
          end

          after do
            FileUtils.rm_rf(trash_file)
          end

          it 'removes matching files' do
            expect(File.exist?(src_file)).not_to be(true)
          end

          it "doesn't move file to trash" do
            expect(File.exist?(File.join(maid.trash_path, File.basename(src_file)))).not_to be(true)
          end
        end

        context 'with files smaller than :remove_over' do
          before do
            allow(maid).to receive(:disk_usage).and_return(1023)

            maid.trash(src_file, remove_over: 1.mb)
          end

          it "doesn't delete them" do
            expect(File.exist?(File.join(maid.trash_path, File.basename(src_file)))).to be(true)
          end
        end
      end
    end

    describe '#remove' do
      let(:src_file) { File.join(test_basedir, 'test_file') }

      before do
        FileUtils.mkdir_p(File.dirname(src_file))
        FileUtils.touch(src_file)
        FileUtils.rm_rf(logfile)
      end

      after do
        FileUtils.rm_rf(File.dirname(src_file))
      end

      context 'with the default options' do
        before do
          maid.remove(src_file)
        end

        it 'removes expanded paths, passing options' do
          expect(File.exist?(src_file)).to be(false)
        end

        it 'logs the remove' do
          expect(File.read(logfile)).to match(/INFO.*Removing #{src_file}/)
        end
      end

      context 'with the :secure option set' do
        before do
          allow(FileUtils).to receive(:rm_r).and_call_original

          maid.remove(src_file, { secure: true })
        end

        it 'passes it to FileUtils.rm_r' do
          expected_args = [File.expand_path(src_file), hash_including(secure: true)]

          expect(FileUtils).to have_received(:rm_r).with(*expected_args)
        end
      end

      context 'with for :force option set' do
        before do
          allow(FileUtils).to receive(:rm_r).and_call_original

          maid.remove(src_file, { force: true })
        end

        it 'sets the force option' do
          expected_args = [File.expand_path(src_file), hash_including(force: true)]

          expect(FileUtils).to have_received(:rm_r).with(*expected_args)
        end
      end

      context 'with multiple paths' do
        let(:src_files) { [src_file, "#{src_file}_2"] }

        before do
          FileUtils.touch(src_files)

          maid.remove(src_files)
        end

        it 'deletes every path' do
          src_files.each do |file|
            expect(File.exist?(file)).to be(false)
          end
        end
      end
    end

    describe '#dir' do
      before do
        @file = (@dir = "#{@home}/Downloads") + '/foo.zip'
        FileUtils.mkdir_p(@dir)
      end

      it 'lists files in a directory' do
        FileUtils.touch(@file)
        expect(@maid.dir('~/Downloads/*.zip')).to eq([@file])
      end

      it 'lists multiple files in alphabetical order' do
        # It doesn't occur with `FakeFS` as far as I can tell, but Ubuntu (and possibly OS X) can give the results out
        # of lexical order.  That makes using the `dry-run` output difficult to use.
        allow(Dir).to receive(:glob).and_return(%w[/home/foo/b.zip /home/foo/a.zip /home/foo/c.zip])
        expect(@maid.dir('~/Downloads/*.zip')).to eq(%w[/home/foo/a.zip /home/foo/b.zip /home/foo/c.zip])
      end

      context 'with multiple files' do
        before do
          @other_file = "#{@dir}/qux.tgz"
          FileUtils.touch(@file)
          FileUtils.touch(@other_file)
        end

        it 'list files in all provided globs' do
          expect(@maid.dir(%w[~/Downloads/*.tgz ~/Downloads/*.zip])).to eq([@file, @other_file])
        end

        it 'lists files when using regexp-like glob patterns' do
          expect(@maid.dir('~/Downloads/*.{tgz,zip}')).to eq([@file, @other_file])
        end
      end

      context 'with multiple directories' do
        let(:src_file) { File.join(test_basedir, 'multi', 'test_file') }
        let(:src_file2) { "#{src_file}_2" }

        before do
          FileUtils.mkdir_p(File.dirname(src_file))
          FileUtils.touch(src_file)
          FileUtils.touch(src_file2)
        end

        it 'lists files in directories when using regexp-like glob patterns' do
          expect(maid.dir("#{File.dirname(src_file)}/*")).to eq([src_file, src_file2])
        end

        it 'lists files in directories when using recursive glob patterns' do
          # TODO: Once we ditch Ruby 2.7, we can do this instead:
          # expect(maid.dir("#{File.dirname(src_file, 2)}/**/test_*")).to eq([src_file, src_file2])
          expect(maid.dir("#{File.dirname(src_file)}/../**/test_*")).to eq([src_file, src_file2])
        end
      end
    end

    describe '#files' do
      let(:file) { File.join(test_basedir, 'test_file') }

      context 'with a single file' do
        before do
          FileUtils.mkdir_p(File.dirname(file))
          FileUtils.touch(file)
        end

        after do
          FileUtils.rm_rf(File.dirname(file))
        end

        it 'lists only files in a directory' do
          expect(maid.files("#{File.dirname(file)}/*_file")).to eq([file])
        end
      end

      context 'with multiple files' do
        let(:first_file) { "#{file}_1" }
        let(:second_file) { "#{file}_2" }

        before do
          FileUtils.mkdir_p(File.dirname(first_file))
          FileUtils.touch(first_file)
          FileUtils.touch(second_file)
        end

        after do
          FileUtils.rm_rf(File.dirname(first_file))
          FileUtils.rm_rf(File.dirname(second_file))
        end

        it 'list files in all provided globs' do
          expect(maid.dir(["#{File.dirname(first_file)}/*_1",
                           "#{File.dirname(second_file)}/*_2",])).to eq([first_file, second_file])
        end

        it 'lists files when using regexp-like glob patterns' do
          expect(@maid.dir("#{File.dirname(first_file)}/*{1,2}")).to eq([first_file, second_file])
        end
      end

      context 'with multiple directories' do
        let(:first_file) { "#{file}_1" }
        let(:second_file) { "#{file}_2" }
        let(:first_dir) { "#{File.dirname(file)}/test_dir_1" }
        let(:second_dir) { "#{File.dirname(file)}/test_dir_2" }
        let(:test_dir) { File.dirname(file) }

        before do
          # Building this:
          # "#{test_dir}/"
          # ├── test_dir_1
          # ├── test_dir_2
          # ├── test_first_file
          # └── test_second_file
          FileUtils.mkdir_p(first_dir)
          FileUtils.mkdir_p(second_dir)
          FileUtils.touch(first_file)
          FileUtils.touch(second_file)
        end

        after do
          FileUtils.rm_rf(test_dir)
        end

        it 'only lists the files' do
          expect(maid.dir("#{test_dir}/**/*{file}*")).to eq([first_file, second_file])
        end
      end
    end

    describe '#escape_glob' do
      it 'escapes characters that have special meanings in globs' do
        expect(@maid.escape_glob('test [tmp]')).to eq('test \\[tmp\\]')
      end
    end

    describe '#mkdir' do
      it 'creates a directory successfully' do
        @maid.mkdir('~/Downloads/Music/Pink.Floyd')
        expect(File.exist?("#{@home}/Downloads/Music/Pink.Floyd")).to be(true)
      end

      it 'logs the creation of the directory' do
        expect(@logger).to receive(:info)
        @maid.mkdir('~/Downloads/Music/Pink.Floyd')
      end

      it 'returns the path of the created directory' do
        expect(@maid.mkdir('~/Reference/Foo')).to eq("#{@home}/Reference/Foo")
      end

      # FIXME: FakeFS doesn't seem to report `File.exist?` properly.  However, this has been tested manually.
      #
      #     it 'respects the noop option' do
      #       @maid.mkdir('~/Downloads/Music/Pink.Floyd')
      #       expect(File.exist?("#@home/Downloads/Music/Pink.Floyd")).to be(false)
      #     end
    end

    describe '#find' do
      before do
        @dir = File.join(test_basedir, 'Source')
        @filename = 'foo.zip'
        @file = File.join(@dir, @filename)
        FileUtils.mkdir_p(File.expand_path(@dir))
        FileUtils.touch(File.expand_path(@file))
        @dir_expand_path = File.expand_path(@dir)
        @fileexpand_path = File.expand_path(@file)
      end

      after do
        FileUtils.rm_rf(@dir)
      end

      it 'delegates to Find.find with an expanded path' do
        f = ->(arg) {}
        expect(Find).to receive(:find).with(@fileexpand_path, &f)
        @maid.find(@file, &f)
      end

      it "returns an array of all the files' names when no block is given" do
        expect(@maid.find(@dir)).to contain_exactly(@dir_expand_path, @fileexpand_path)
      end
    end

    describe '#locate' do
      it 'locates a file by name' do
        expect(@maid).to receive(:cmd).and_return("/a/foo.zip\n/b/foo.zip\n")
        expect(@maid.locate('foo.zip')).to eq(['/a/foo.zip', '/b/foo.zip'])
      end
    end

    describe '#downloaded_from' do
      before do
        allow(Platform).to receive(:osx?).and_return(true)
      end

      it 'determines the download site' do
        expect(@maid).to receive(:cmd).and_return(%((\n    "http://www.site.com/foo.zip",\n"http://www.site.com/"\n)))
        expect(@maid.downloaded_from('foo.zip')).to eq(['http://www.site.com/foo.zip', 'http://www.site.com/'])
      end
    end

    describe '#downloading?' do
      it 'detects a normal file as not being downloaded' do
        expect(@maid.downloading?('foo.zip')).to be(false)
      end

      it 'detects when downloading in Firefox' do
        expect(@maid.downloading?('foo.zip.part')).to be(true)
      end

      it 'detects when downloading in Chrome' do
        expect(@maid.downloading?('foo.zip.crdownload')).to be(true)
      end

      it 'detects when downloading in Safari' do
        expect(@maid.downloading?('foo.zip.download')).to be(true)
      end
    end

    describe '#duration_s' do
      it 'determines audio length' do
        expect(@maid).to receive(:cmd).and_return('235.705')
        expect(@maid.duration_s('foo.mp3')).to eq(235.705)
      end
    end

    describe '#zipfile_contents' do
      it 'inspects the contents of a .zip file' do
        entries = [double(name: 'foo.exe'), double(name: 'README.txt'), double(name: 'subdir/anything.txt')]
        allow(Zip::File).to receive(:open).and_yield(entries)

        expect(@maid.zipfile_contents('foo.zip')).to eq(['README.txt', 'foo.exe', 'subdir/anything.txt'])
      end
    end

    describe '#disk_usage' do
      it 'gives the disk usage of a file' do
        expect(@maid).to receive(:cmd).and_return('136     foo.zip')
        expect(@maid.disk_usage('foo.zip')).to eq(136)
      end

      context 'when the file does not exist' do
        it 'raises an error' do
          expect(@maid).to receive(:cmd).and_return("du: cannot access `foo.zip': No such file or directory")
          expect { @maid.disk_usage('foo.zip') }.to raise_error(RuntimeError)
        end
      end
    end

    describe '#created_at' do
      let(:file) { File.join(test_basedir, 'test_file') }

      before do
        FileUtils.mkdir_p(File.dirname(file))
        FileUtils.touch(file)
      end

      after do
        FileUtils.rm_rf(File.dirname(file))
      end

      it 'gives the created time of the file' do
        expect(maid.created_at(file)).to eq(File.stat(file).ctime)
      end
    end

    describe '#accessed_at' do
      # FakeFS does not implement atime.
      it 'gives the last accessed time of the file' do
        expect(File).to receive(:atime).with("#{@home}/foo.zip").and_return(@now)
        expect(@maid.accessed_at('~/foo.zip')).to eq(@now)
      end

      it 'triggers deprecation warning when last_accessed is used, but still run' do
        expect(File).to receive(:atime).with("#{@home}/foo.zip").and_return(@now)
        expect(@maid).to have_deprecated_method(:last_accessed)
        expect(@maid.last_accessed('~/foo.zip')).to eq(@now)
      end
    end

    describe '#modified_at' do
      before do
        @path = File.join('~', 'test.txt')
        FileUtils.touch(File.expand_path(@path))
      end

      it 'gives the modified time of the file' do
        Timecop.freeze(@now) do
          File.write(File.expand_path(@path), 'Test')
        end

        # use to_i to ignore milliseconds during test
        expect(@maid.modified_at(@path).to_i).to eq(@now.to_i)
      end
    end

    describe '#size_of' do
      before do
        @file = '~/foo.zip'
      end

      it 'gives the size of the file' do
        expect(File).to receive(:size).with(@file).and_return(42)
        expect(@maid.size_of(@file)).to eq(42)
      end
    end

    describe '#checksum_of' do
      before do
        @file = '~/test.txt'
      end

      it 'returns the checksum of the file' do
        expect(File).to receive(:read).with(@file).and_return('contents')
        expect(@maid.checksum_of(@file)).to eq(Digest::SHA1.hexdigest('contents'))
      end
    end

    describe '#git_piston' do
      it 'is deprecated' do
        expect(@maid).to have_deprecated_method(:git_piston)
        @maid.git_piston('~/code/projectname')
      end

      it 'ands pushes the given git repository, logging the action' do
        expect(@maid).to receive(:cmd).with(%(cd #{@home}/code/projectname && git pull && git push 2>&1))
        expect(@logger).to receive(:info)
        @maid.git_piston('~/code/projectname')
      end
    end

    describe '#sync' do
      before do
        @src_dir = '~/Downloads/'
        @dst_dir = '~/Reference'
      end

      it 'syncs the expanded paths, retaining backslash' do
        expect(@maid).to receive(:cmd).with(%(rsync -a -u #{@home}/Downloads/ #{@home}/Reference 2>&1))
        @maid.sync(@src_dir, @dst_dir)
      end

      it 'logs the action' do
        expect(@logger).to receive(:info)
        @maid.sync(@src_dir, @dst_dir)
      end

      it 'has no options' do
        expect(@maid).to receive(:cmd).with(%(rsync  #{@home}/Downloads/ #{@home}/Reference 2>&1))
        @maid.sync(@src_dir, @dst_dir, archive: false, update: false)
      end

      it 'adds all options' do
        expect(@maid).to receive(:cmd).with(%(rsync -a -v -u -m --exclude=.git --delete #{@home}/Downloads/ #{@home}/Reference 2>&1)) # rubocop:disable Layout/LineLength
        @maid.sync(@src_dir, @dst_dir, archive: true, update: true, delete: true, verbose: true,
                                       prune_empty: true, exclude: '.git',)
      end

      it 'adds multiple exlcude options' do
        expect(@maid).to receive(:cmd)
          .with(%(rsync -a -u --exclude=.git --exclude=.rvmrc #{@home}/Downloads/ #{@home}/Reference 2>&1))
        @maid.sync(@src_dir, @dst_dir, exclude: ['.git', '.rvmrc'])
      end

      context 'when file_options[:noop] is true' do
        let!(:original_file_options) { @maid.file_options.clone }

        before do
          @maid.file_options[:noop] = true
        end

        after do
          @maid.file_options[:noop] = original_file_options[:noop]
        end

        it 'adds noop option' do
          expect(@maid).to receive(:cmd).with(%(rsync -a -u -n #{@home}/Downloads/ #{@home}/Reference 2>&1))
          @maid.sync(@src_dir, @dst_dir)
        end
      end
    end

    describe '#copy' do
      let(:src_file) { File.join(test_basedir, 'src', 'test_file') }
      let(:src_dir) { File.dirname(src_file) }
      let(:dst_file) { File.join(test_basedir, 'dest', 'test_file') }
      let(:dst_dir) { File.dirname(dst_file) }

      before do
        FileUtils.mkdir_p(File.expand_path(src_dir))
        FileUtils.touch(File.expand_path(src_file))
        FileUtils.mkdir_p(File.expand_path(dst_dir))
        FileUtils.rm_rf(logfile)
      end

      after do
        FileUtils.rm_rf(src_dir)
        FileUtils.rm_rf(dst_dir)
      end

      it 'copies expanded paths, passing file_options' do
        @maid.copy(src_file, dst_dir)
        expect(File.exist?(File.expand_path(dst_file))).to be_truthy
      end

      context "when destination doesn't exist" do
        before do
          maid.copy(src_file, dst_dir)
        end

        it 'logs the copy' do
          expect(File.read(logfile)).to match(/INFO.*cp.*#{dst_dir}/)
        end
      end

      context 'when destination exists' do
        it 'does not copy if the target already exists' do
          FileUtils.touch(File.expand_path(dst_file))
          expect(@logger).to receive(:warn)

          @maid.copy(src_file, dst_dir)
        end
      end

      context 'with multiple `from` paths' do
        let(:first_file) { File.join(src_dir, 'bar.zip') }
        let(:second_file) { File.join(src_dir, 'baz.zip') }
        let(:src_files) { [first_file, second_file] }

        before do
          src_files.each { |file| FileUtils.touch(File.expand_path(file)) }
        end

        it 'copies all files' do
          @maid.copy(src_files, dst_dir)

          expect(File.exist?(File.expand_path(first_file))).to be_truthy
          expect(File.exist?(File.expand_path(second_file))).to be_truthy
        end
      end
    end

    describe '#dupes_in' do
      it 'lists duplicate files in arrays' do
        dupes = maid.dupes_in(filefixtures_glob)
        expect(dupes.first).to be_a(Array)

        basenames = dupes.flatten.map { |p| File.basename(p) }
        expect(basenames).to eq(%w[1.zip bar.zip foo.zip])
      end
    end

    describe '#verbose_dupes_in' do
      it 'lists all but the shortest-named dupe' do
        dupes = maid.verbose_dupes_in(filefixtures_glob)

        basenames = dupes.flatten.map { |p| File.basename(p) }
        expect(basenames).to eq(%w[bar.zip foo.zip])
      end
    end

    describe '#newest_dupes_in' do
      it 'lists all but the oldest dupe' do
        # FIXME: Broken on Ruby 2.1.0-preview2, maybe because of FakeFS
        #
        #     oldest_path = "#{filefixtures_path}/foo.zip"
        #     FileUtils.touch(oldest_path, :mtime => Time.new(1970, 1, 1))

        FileUtils.touch("#{filefixtures_path}/bar.zip")
        FileUtils.touch("#{filefixtures_path}/1.zip")

        dupes = maid.newest_dupes_in(filefixtures_glob)

        basenames = dupes.flatten.map { |p| File.basename(p) }
        expect(basenames).to match_array(%w[bar.zip 1.zip])
      end
    end

    describe '#dimensions_px' do
      context 'given a JPEG image' do
        it 'reports the known size' do
          expect(maid.dimensions_px(image_path)).to eq([32, 32])
        end
      end

      context 'given an unknown type' do
        it 'returns nil' do
          expect(maid.dimensions_px(unknown_path)).to be_nil
        end
      end
    end

    describe '#location_city' do
      context 'given a JPEG image' do
        it 'reports the known location', vcr: { record: :new_episodes } do
          sydney_path = File.join(filefixtures_path, 'sydney.jpg')
          expect(maid.location_city(sydney_path)).to eq('Sydney, New South Wales, AU')
        end
      end

      context 'given an unknown type' do
        it 'returns nil' do
          expect(maid.location_city(unknown_path)).to be_nil
        end
      end
    end

    describe '#mime_type' do
      context 'given a JPEG image' do
        it 'reports "image/jpeg"' do
          expect(maid.mime_type(image_path)).to eq('image/jpeg')
        end
      end

      context 'given an unknown type' do
        it 'returns nil' do
          expect(maid.mime_type(unknown_path)).to be_nil
        end
      end
    end

    describe '#media_type' do
      context 'given a JPEG image' do
        it 'reports "image"' do
          expect(maid.media_type(image_path)).to eq('image')
        end
      end

      context 'given an unknown type' do
        it 'returns nil' do
          expect(maid.media_type(unknown_path)).to be_nil
        end
      end
    end

    describe '#where_content_type' do
      context 'given "image"' do
        it 'only lists the fixture JPEGs' do
          matches = maid.where_content_type(maid.dir(filefixtures_glob), 'image')

          expect(matches.length).to eq(2)
          expect(matches.first).to end_with('spec/fixtures/files/ruby.jpg')
          expect(matches.last).to end_with('spec/fixtures/files/sydney.jpg')
        end
      end
    end

    describe '#tree_empty?' do
      before do
        @root = '~/Source'
        @empty_dir = (@parent_of_empty_dir = @root + '/empty-parent') + '/empty'
        @file = (@non_empty_dir = @root + '/non-empty') + '/file.txt'
        FileUtils.mkdir_p(@empty_dir)
        FileUtils.mkdir_p(@non_empty_dir)
        FileUtils.touch(@file)
      end

      it 'returns false for non-empty directories' do
        expect(maid.tree_empty?(@non_empty_dir)).to be(false)
      end

      it 'returns true for empty directories' do
        expect(maid.tree_empty?(@empty_dir)).to be(true)
      end

      it 'returns true for directories with empty subdirectories' do
        expect(maid.tree_empty?(@parent_of_empty_dir)).to be(true)
      end

      it 'returns false for directories with non-empty subdirectories' do
        expect(maid.tree_empty?(@root)).to be(false)
      end
    end

    describe '#ignore_child_dirs' do
      # FIXME: Example is too long, shouldn't need the rubocop::disable
      it 'filters out any child directory' do # rubocop:disable RSpec/ExampleLength
        src = [
          'a',
          'b',
          'b/x',
          'c',
          'c/x',
          'c/y',
          'd/x',
          'd/y',
          'e/x/y',
          'e/x/y/z',
          'f/x/y/z',
          'g/x/y',
          'g/x/z',
          'g/y/a/b',
          'g/y/a/c',
        ]
        expected = [
          'a', # no child directories
          'b', # ignore b/x
          'c', # ignore c/x and c/y
          'd/x', # no child directories
          'd/y', # no child directories
          'e/x/y', # ignore e/x/y/z
          'f/x/y/z', # no empty parents
          'g/x/y', # g/x isn't empty
          'g/x/z',
          'g/y/a/b', # g/y/a isn't empty
          'g/y/a/c',
        ].sort

        expect(maid.ignore_child_dirs(src).sort).to eq(expected)
      end
    end
  end

  describe 'OSX tag support', fakefs: false do
    let(:test_basedir) { '/tmp/maid-specs' }
    let(:test_file) { File.join(test_basedir, 'tag.zip') }
    let(:test_dir) { File.dirname(test_file) }
    let(:filename) { File.basename(test_file) }
    let(:original_file_options) { maid.file_options.clone }
    let(:maid) { Maid.new(log_device: File::NULL) }

    before do
      FileUtils.mkdir_p(test_dir)
      FileUtils.touch(test_file)
      maid.file_options[:noop] = false
    end

    after do
      FileUtils.rm_r(test_dir)
      maid.file_options[:noop] = original_file_options[:noop]
    end

    describe '#tags' do
      it 'returns tags from a file that has one' do
        if Platform.has_tag_available?
          maid.file_options[:noop] = false
          maid.add_tag(test_file, 'Test')
          expect(maid.tags(test_file)).to eq(['Test'])
        end
      end

      it 'returns tags from a file that has serveral tags' do
        if Platform.has_tag_available?
          maid.file_options[:noop] = false
          maid.add_tag(test_file, %w[Test Twice])
          expect(maid.tags(test_file)).to eq(%w[Test Twice])
        end
      end
    end

    describe '#has_tags?' do
      it 'returns true for a file with tags' do
        if Platform.has_tag_available?
          maid.add_tag(test_file, 'Test')
          expect(maid.has_tags?(test_file)).to be(true)
        end
      end

      it 'returns false for a file without tags' do
        expect(maid.has_tags?(test_file)).to be(false)
      end
    end

    describe '#contains_tag?' do
      it 'returns true a file with the given tag' do
        if Platform.has_tag_available?
          maid.add_tag(test_file, 'Test')
          expect(maid.contains_tag?(test_file, 'Test')).to be(true)
          expect(maid.contains_tag?(test_file, 'Not there')).to be(false)
        end
      end
    end

    describe '#add_tag' do
      it 'adds the given tag to a file' do
        if Platform.has_tag_available?
          maid.add_tag(test_file, 'Test')
          expect(maid.contains_tag?(test_file, 'Test')).to be(true)
        end
      end
    end

    describe '#remove_tag' do
      it 'removes the given tag from a file' do
        if Platform.has_tag_available?
          maid.add_tag(test_file, 'Test')
          expect(maid.contains_tag?(test_file, 'Test')).to be(true)
          maid.remove_tag(test_file, 'Test')
          expect(maid.contains_tag?(test_file, 'Test')).to be(false)
        end
      end
    end

    describe '#set_tag' do
      it 'sets the given tags on a file' do
        if Platform.has_tag_available?
          maid.set_tag(test_file, 'Test')
          expect(maid.contains_tag?(test_file, 'Test')).to be(true)
          maid.set_tag(test_file, %w[Test Twice])
          expect(maid.contains_tag?(test_file, 'Test')).to be(true)
          expect(maid.contains_tag?(test_file, 'Twice')).to be(true)
        end
      end
    end
  end
end
