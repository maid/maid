require 'forwardable'

module Maid
  class Logger
    extend Forwardable

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal, :unknown

    def initialize(device:, logger: ::Logger, level: ::Logger::INFO)
      create_logfile_dir(device) if device.is_a? String

      @logger = logger.new(device)
      @logger.progname = 'Maid'
      @logger.level = level
      @logger.debug(self.class) { "Will log to #{device} with level #{level}" }
    end

    private

    attr_reader :logger

    def create_logfile_dir(device)
      FileUtils.mkdir_p(File.dirname(device))
    end
  end
end
