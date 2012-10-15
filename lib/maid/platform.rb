require 'rbconfig'

module Maid::Platform
  class << self
    def linux?
      !!(host_os =~ /linux/i)
    end

    def osx?
      !!(host_os =~ /darwin/i)
    end

    private

    def host_os
      RbConfig::CONFIG['host_os']
    end
  end
end
