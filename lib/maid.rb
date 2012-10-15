require 'deprecated'
Deprecated.set_action(:warn)

module Maid
  autoload :App, 'maid/app'
  autoload :Maid, 'maid/maid'
  autoload :Tools, 'maid/tools'
  autoload :NumericExtensions, 'maid/numeric_extensions'
  autoload :Platform, 'maid/platform'
  autoload :Rule, 'maid/rule'
  autoload :VERSION, 'maid/version'

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

# TODO Is there a no-conflict way of including the extensions?
