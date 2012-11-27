require 'ohai'
require 'xdg'

# > What is Dependency Testing?
# >
# > Examines an application's requirements for pre-existing software, initial states and configuration in order to maintain proper functionality.
# >
# > -- http://sqa.fyicenter.com/FAQ/Software-QA-Testing/What_is_Dependency_Testing_.html
describe 'Dependency expectations' do
  describe Ohai do
    before do
      @ohai = Ohai::System.new
      @ohai.all_plugins
    end
  
    it 'has platform information' do
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
      data_home = XDG['DATA_HOME'].to_s
      data_home.should match(%r{^/})
      data_home.should match(%r{/\.local/share$})
    end
  end
end
