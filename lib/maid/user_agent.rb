require 'ohai'

# Version information for the host system, kind of like a browser's user agent string.
#
# This could potentially be a part of `Platform` or `VERSION` but both of those are used when building the gemspec, which can't depend on other gems.
module Maid::UserAgent
  class << self
	  # This used to be called `#to_s`, but that made things difficult when testing.
    def value
      ohai = Ohai::System.new
      ohai.all_plugins
      ohai_rb = ohai['languages']['ruby']

      maid     = "Maid/#{ ::Maid.const_get(:VERSION) }"
      platform = "#{ ohai['platform'] }/#{ ohai['platform_version'] }"
      ruby     = "Ruby/#{ ohai_rb['version'] } #{ ohai_rb['platform'] }"
      
      "#{ maid } (#{ platform }; #{ ruby })"
    end
  end
end
