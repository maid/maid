module Maid
  autoload :Maid, 'maid/maid'
  autoload :Tools, 'maid/tools'
  autoload :NumericExtensions, 'maid/numeric_extensions'
  autoload :Rule, 'maid/rule'

  class << self
    def with_instance(instance)
      @instance = instance
      result = yield
      @instance = nil
      result
    end

    def rules(&block)
      @instance.instance_eval(&block)
    end
  end
end

class Numeric
  include Maid::NumericExtensions
end
