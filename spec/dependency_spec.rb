require 'logger'
require 'mime/types'
require 'rbconfig'
require 'stringio'
require 'xdg'
require 'zip'

# > What is Dependency Testing?
# >
# > Examines an application's requirements for pre-existing software, initial states and configuration in order to
# > maintain proper functionality.
# >
# > -- http://sqa.fyicenter.com/FAQ/Software-QA-Testing/What_is_Dependency_Testing_.html
describe 'Dependency expectations' do
  before do
    @file_fixtures_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/files/')
  end

  describe Logger do
    # Depending on the situation, `Logger` might have been overwritten to have a different interface.  (I'm looking at you, Rails.)
    it 'logs with the expected interface' do
      io = StringIO.new
      logger = Logger.new(io)
      logger.info('my message')
      logger.formatter = lambda { |_, _, _, msg| msg }
      expect(io.string).to match(/my message/)
    end
  end

  describe MIME::Types do
    it 'reports media types and sub types when given a path' do
      types = MIME::Types.type_for('anything.jpg')
      expect(types.length).to eq(1)
      type = types[0]
      expect(type.media_type).to eq('image')
      expect(type.sub_type).to eq('jpeg')
    end

    context 'when the type is unknown' do
      it 'returns []' do
        types = MIME::Types.type_for('unknown.foo')
        expect(types.length).to eq(0)
        expect(types[0]).to be_nil
      end
    end
  end

  describe RbConfig do
    it 'identifies the host operating system' do
      expect(RbConfig::CONFIG['host_os']).to match(/[a-z]+/)
    end
  end

  describe XDG do
    it 'has DATA_HOME' do
      # FIXME: This test could be cleaner.  We can't depend on the directory to already exist, even on systems that use
      # the XDG standard.  This seems safe enough for now.
      #
      # More info:
      #
      # * [XDG Base Directory Specification](http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html)
      expect(XDG['DATA_HOME'].to_s).to match(%r{^/.*?/\.local/share$})
    end
  end

  describe Zip::File do
    it 'makes entries available with #entries' do
      Zip::File.open("#@file_fixtures_path/foo.zip") do |zip_file|
        expect(zip_file.entries.map { |entry| entry.name }).to match_array(%w(README.txt foo.exe subdir/anything.txt))
      end
    end

    it 'supports UTF-8 filenames' do
      # Filename is a Japanese character
      Zip::File.open("#@file_fixtures_path/\343\201\225.zip") do |zip_file|
        expect(zip_file.entries.map { |entry| entry.name }).to eq(%w(anything.txt))
      end
    end
  end
end
