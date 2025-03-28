require 'listen'

class Maid::Watch
  include Maid::RuleContainer

  attr_reader :path, :listener, :logger

  def initialize(maid, path, options = {}, &)
    @maid = maid

    if options.nil? || options.empty?
      @lazy = true
      @options = { wait_for_delay: 10,
                   ignore: Maid::Downloading.downloading_file_regexps, }
    else
      @lazy = options.delete(:lazy) { |_key| true }
      @options = options
    end

    @logger = maid.logger # TODO: Maybe it's better to create seperate loggers?
    @path = File.expand_path(path)
    initialize_rules(&)
  end

  def run
    return if rules.empty?

    @listener = Listen.to(path, @options) do |modified, added, removed|
      follow_rules(modified, added, removed) if !@lazy || added.any? || removed.any?
    end

    @listener.start
  end

  def stop
    @listener.stop
  end

  def join
    @listener.thread.join unless @listener.nil? || @listener.paused?
  end
end
