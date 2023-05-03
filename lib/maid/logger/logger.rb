require 'forwardable'

module Maid
  class Logger
    extend Forwardable
    attr_reader :device

    def initialize(device:, logger: ::Logger, level: ::Logger::INFO)
      @device = device
      create_logfile if device.is_a? String
      @logger = logger.new(device)
      @logger.level = level
    end

    # %i[debug info warn error fatal unknown].each do |m|
    #   define_method(m) do |msg|
    #     log(__method__, msg)
    #   end
    # end
    def debug(msg)
      logger.debug(msg)
    end

    def info(msg)
      log(__method__, msg)
    end

    def warn(msg)
      log(__method__, msg)
    end

    def error(msg)
      log(__method__, msg)
    end

    def fatal(msg)
      log(__method__, msg)
    end

    def unknown(msg)
      log(__method__, msg)
    end

    def log(level, msg)
      logger.send(level, msg)
    end

    private

    attr_reader :logger

    def create_logfile
      FileUtils.mkdir_p(File.dirname(device))
    end
  end
end
