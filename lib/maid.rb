module Maid
  autoload :Maid, 'maid/maid'
  autoload :Tools, 'maid/tools'
  autoload :NumericExtensions, 'maid/numeric_extensions'

  def self.rules(&block)
    Tools.class_eval(&block)
  end
end

class Numeric
  include Maid::NumericExtensions
end
