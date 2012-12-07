require 'ohai'
require 'xdg'

# > What is Dependency Testing?
# >
# > Examines an application's requirements for pre-existing software, initial states and configuration in order to
# > maintain proper functionality.
# >
# > -- http://sqa.fyicenter.com/FAQ/Software-QA-Testing/What_is_Dependency_Testing_.html
describe 'Dependency expectations' do
  describe Ohai do
    before do
      @ohai = Ohai::System.new
      # FIXME: For some reason this is really slow when using `guard`
      @ohai.require_plugin('os')
    end
  
    it 'has platform information' do
      @ohai.require_plugin('platform')
      @ohai['platform'].should match(/[a-z]+/i)
      @ohai['platform_version'].should match(/[0-9]+/)
    end
  
    it 'has Ruby information' do
      ruby = @ohai['languages']['ruby']
      ruby['version'].should match(/^[0-9\.]+$/i)
      ruby['platform'].should match(/[a-z0-9]+/i)
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
      XDG['DATA_HOME'].to_s.should match(%r{^/.*?/\.local/share$})
    end
  end
end
