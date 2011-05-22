module Maid
  autoload :Maid, 'maid/maid'
  autoload :Tools, 'maid/tools'
  autoload :NumericExtensions, 'maid/numeric_extensions'
end

class Numeric
  include Maid::NumericExtensions
end
