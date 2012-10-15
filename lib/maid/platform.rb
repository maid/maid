require 'rbconfig'

module Maid::Platform
  class << self
    def host_os
      RbConfig::CONFIG['host_os']
    end

    def linux?
      !!(host_os =~ /linux/i)
    end

    def osx?
      !!(host_os =~ /darwin/i)
    end
  end
end
