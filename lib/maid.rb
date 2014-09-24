require 'deprecated'
require 'escape'
Deprecated.set_action(:warn)

# Must be in this order:
require 'maid/version'
require 'maid/tools'
require 'maid/maid'

# Alphabetical:
require 'maid/app'
require 'maid/numeric_extensions'
require 'maid/platform'
require 'maid/rake/single_rule'
require 'maid/rule'
require 'maid/trash_migration'
require 'maid/user_agent'

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
      @instance.instance_eval(&block)
    end
  end
end

class Numeric
  include Maid::NumericExtensions::Time
  include Maid::NumericExtensions::SizeToKb
end
