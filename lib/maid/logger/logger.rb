require 'forwardable'

module Maid
  class Logger
    extend Forwardable
    attr_reader :device

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal, :unknown

    def initialize(device:, logger: ::Logger, level: ::Logger::INFO)
      @device = device
      create_logfile_dir if device.is_a? String
      @logger = logger.new(device)
      @logger.level = level
    end

    private

    attr_reader :logger

    def create_logfile_dir
      FileUtils.mkdir_p(File.dirname(device))
    end
  end
end
