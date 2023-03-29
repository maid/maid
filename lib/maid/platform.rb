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

    def has_tag_available?
      osx? && system('which -s tag')
    end
  end

  # Commands based on OS type
  class Commands
    class << self
      # logicaly decides which locate command to use
      def locate
        Maid::Platform.linux? ? 'locate' : 'mdfind -name'
      end
    end
  end
end
