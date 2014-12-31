# Version information for the host system, kind of like a browser's user agent string.
#
# This could potentially be a part of `Platform` or `VERSION` but both of those are used when building the gemspec,
# which can't depend on other gems.  FIXME: That's no longer accurate, so this could be `Platform.user_agent` instead.
module Maid::UserAgent
  class << self
    def short
      "Maid/#{ ::Maid.const_get(:VERSION) }"
    end

    # This used to be called `#to_s`, but that made things difficult when testing.
    def value
      "#{ short } (#{ RUBY_DESCRIPTION })"
    end
  end
end
