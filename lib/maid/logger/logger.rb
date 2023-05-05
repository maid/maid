require 'forwardable'

module Maid
  # Provides an abstraction over the ::Logger class to streamline logger
  # instantiation, defaults, and interface.
  class Logger
    extend Forwardable

    # !@method debug
    #   @see https://docs.ruby-lang.org/en/master/Logger.html
    # !@method info
    #   @see https://docs.ruby-lang.org/en/master/Logger.html
    # !@method warn
    #   @see https://docs.ruby-lang.org/en/master/Logger.html
    # !@method error
    #   @see https://docs.ruby-lang.org/en/master/Logger.html
    # !@method fatal
    #   @see https://docs.ruby-lang.org/en/master/Logger.html
    # !@method unknown
    #   @see https://docs.ruby-lang.org/en/master/Logger.html
    def_delegators :@logger, :debug, :info, :warn, :error, :fatal, :unknown

    # Creates a new logger
    # @param device [String, IO] the device to log to
    # @param logger [::Logger] the logger to use
    # @param level [Integer] the log level
    # @return [::Logger] the new logger
    # @see https://docs.ruby-lang.org/en/master/Logger.html#class-Logger-label-Entries
    # @example Create a new logger and log an info message
    #   # with the Maid namespace
    #   logger = Logger.new(device: '/tmp/my.log')
    #   logger.info('hello!')
    #   # or
    #   logger.info { 'hello!' } # Preferred, see Ruby's Logger docs for details.
    # @example Log a debug message with the full module's name
    #   module Maid
    #     class MyClass
    #       # ...
    #       def my_method
    #   logger.debug(self.class) { 'a message' } # => "Maid::MyClass: a message"
    def initialize(device:, logger: ::Logger, level: ::Logger::INFO)
      create_logfile_dir(device) if device.is_a? String

      # Keep the 5 last logs, with a max size of 10MiB each.
      logger_options = { shift_age: 5, shift_size: 10 * 1_048_576 }
      @logger = logger.new(device, logger_options[:shift_age],
                           logger_options[:shift_size],)
      @logger.progname = 'Maid'
      @logger.level = level
      @logger.debug(self.class) { "Will log to #{device} with level #{level}" }
    end

    private

    # @return [::Logger] the ::Logger instance
    attr_reader :logger

    # @param filepath [String] full path to the log file
    def create_logfile_dir(filepath)
      FileUtils.mkdir_p(File.dirname(filepath))
    end
  end
end
