require 'deprecated'
require 'escape'
Deprecated.set_action(:warn)

# Must be in this order:
require 'maid/version'
require 'maid/logger/logger'
require 'maid/downloading'
require 'maid/tools'
require 'maid/rule_container'
require 'maid/maid'

# Alphabetical:
require 'maid/app'
require 'maid/numeric_extensions'
require 'maid/platform'
require 'maid/rake/single_rule'
require 'maid/rake/task'
require 'maid/rule'
require 'maid/trash_migration'
require 'maid/user_agent'
require 'maid/watch'
require 'maid/repeat'

module Maid
  class << self
    # Execute the block with the Maid instance set to <tt>instance</tt>.
    def with_instance(instance)
      @instance = instance
      result = yield
      @instance = nil
      result
    end

    # Define rules for the Maid instance.
    def rules(&block)
      @instance.instance_exec(&block)
    end
  end
end

class Numeric
  include Maid::NumericExtensions::Time
  include Maid::NumericExtensions::SizeToKb
end
