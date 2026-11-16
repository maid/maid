require 'dimensions'
require 'exifr/jpeg'
require 'fileutils'
require 'logger'
require 'geocoder'
require 'mime/types'
require 'open3'
require 'rbconfig'
require 'stringio'
require 'tmpdir'
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

  # Dependabot evaluates the gemspec in an isolated copy of the repo.  Its
  # sanitizer wraps every `require`/`require_relative` in
  # `begin ... rescue LoadError ... end`, and it only fetches files that are
  # referenced with `require_relative` (plain `require`s are not fetched).  So a
  # constant defined in a plain-`require`d local file (such as `Maid::SUMMARY`
  # in `lib/maid/version.rb`) ends up undefined, and the security update fails
  # with `uninitialized constant Maid`.
  describe 'maid.gemspec' do
    let(:repo_root) { File.expand_path('..', __dir__) }

    def dependabot_sanitized_gemspec(dir)
      gemspec = File.read(File.join(repo_root, 'maid.gemspec'))

      gemspec.scan(/require_relative\s+['"]([^'"]+)['"]/).flatten.each do |path|
        destination = File.join(dir, "#{path}.rb")
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(File.join(repo_root, "#{path}.rb"), destination)
      end

      gemspec.gsub(/^(\s*)(require_relative|require)\b.*$/) do
        "begin\n#{Regexp.last_match(0)}\nrescue LoadError\nend"
      end
    end

    def load_gemspec_without_bundler(dir)
      command = [
        RbConfig.ruby, '-e',
        'abort("gemspec failed to load") unless Gem::Specification.load("maid.gemspec")',
      ]
      Bundler.with_unbundled_env { Open3.capture2e(*command, chdir: dir) }
    end

    it 'loads when evaluated the way Dependabot does' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'maid.gemspec'), dependabot_sanitized_gemspec(dir))

        output, status = load_gemspec_without_bundler(dir)

        expect(status).to be_success, output
      end
    end
  end

  describe Logger do
    # Depending on the situation, `Logger` might have been overwritten to have
    # a different interface.  (I'm looking at you, Rails.)
    it 'logs with the expected interface' do
      io = StringIO.new
      logger = Logger.new(io)
      logger.info('my message')
      logger.formatter = ->(_, _, _, msg) { msg }
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
      Zip::File.open("#{@file_fixtures_path}/foo.zip") do |zip_file|
        expect(zip_file.entries.map { |entry| entry.name }).to match_array(%w[README.txt foo.exe subdir/anything.txt])
      end
    end

    it 'supports UTF-8 filenames' do
      # Filename is a Japanese character
      Zip::File.open("#{@file_fixtures_path}/\343\201\225.zip") do |zip_file|
        expect(zip_file.entries.map { |entry| entry.name }).to eq(%w[anything.txt])
      end
    end
  end

  describe Dimensions do
    it 'returns dimensions as an array' do
      expect(Dimensions.dimensions("#{@file_fixtures_path}/sydney.jpg")).to eq([100, 75])
    end
  end

  describe EXIFR::JPEG do
    it 'returns latitude and longitude' do
      gps = EXIFR::JPEG.new("#{@file_fixtures_path}/sydney.jpg").gps
      expect([gps.latitude, gps.longitude]).to eq([-33.85608611111111, 151.219925])
    end
  end

  describe Geocoder, vcr: { record: :new_episodes } do
    it 'translates latitude and longitude into street addresses' do
      city = Geocoder.search('-33.85608611111111,151.219925').map { |location| location.city }.uniq.compact
      expect(city).to eq(['Sydney'])
    end
  end
end
