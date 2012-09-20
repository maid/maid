module Maid::NumericExtensions
  # From https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/numeric/time.rb, with some modifications since active_support ruins Logger by overriding its functionality.
  module Time
    # Enables the use of time calculations and declarations, like 45.minutes + 2.hours + 4.years.
    #
    # These methods use Time#advance for precise date calculations when using from_now, ago, etc.
    # as well as adding or subtracting their results from a Time object. For example:
    #
    #   # equivalent to Time.now.advance(:months => 1)
    #   1.month.from_now
    #
    #   # equivalent to Time.now.advance(:years => 2)
    #   2.years.from_now
    #
    #   # equivalent to Time.now.advance(:months => 4, :years => 5)
    #   (4.months + 5.years).from_now
    #
    # While these methods provide precise calculation when used as in the examples above, care
    # should be taken to note that this is not true if the result of `months', `years', etc is
    # converted before use:
    #
    #   # equivalent to 30.days.to_i.from_now
    #   1.month.to_i.from_now
    #
    #   # equivalent to 365.25.days.to_f.from_now
    #   1.year.to_f.from_now
    #
    # In such cases, Ruby's core
    # Date[http://stdlib.rubyonrails.org/libdoc/date/rdoc/index.html] and
    # Time[http://stdlib.rubyonrails.org/libdoc/time/rdoc/index.html] should be used for precision
    # date and time arithmetic
    def seconds
      self
    end
    alias :second :seconds

    def minutes
      self * 60
    end
    alias :minute :minutes

    def hours
      self * 3600
    end
    alias :hour :hours

    def days
      self * 24.hours
    end
    alias :day :days

    def weeks
      self * 7.days
    end
    alias :week :weeks

    def fortnights
      self * 2.weeks
    end
    alias :fortnight :fortnights

    # Reads best without arguments:  10.minutes.ago
    def ago(time = ::Time.now)
      time - self
    end

    # Reads best with argument:  10.minutes.until(time)
    alias :until :ago

    # Reads best with argument:  10.minutes.since(time)
    def since(time = ::Time.now)
      time + self
    end

    # Reads best without arguments:  10.minutes.from_now
    alias :from_now :since

    ######################
    ### Maid additions ###
    ######################

    # TODO find a better place for these to live?

    # Reads well in a case like:
    #
    #   1.week.since? accessed_at('filename')
    def since?(other_time)
      other_time < self.ago
    end
  end
  module SizeToKb
    # Enables Computer disk size conversion into kilobytes.
    #
    # Can convert megabytes, gigabytes and terabytes.
    # Handles full name (megabyte), plural (megabytes) and symobl (mb/mB).
    #
    #   1.megabyte = 1024 kilobytes

    def kb
      self
    end
    alias :kilobytes :kb
    alias :kilobyte :kb
    alias :kB :kb

    def mb
      self * 1024 ** 1
    end
    alias :megabytes :mb
    alias :megabyte :mb
    alias :mB :mb

    def gb
      self * 1024 ** 2
    end
    alias :gigabytes :gb
    alias :gigabyte :gb
    alias :gB :gb

    def tb
      self * 1024 ** 3
    end
    alias :terabytes :tb
    alias :terabyte :tb
    alias :tB :tb
  end
end
