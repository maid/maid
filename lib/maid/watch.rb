require 'listen'
class Maid::Watch
  include Maid::RuleContainer
  include Maid::Downloading

  attr_reader :path, :listener, :logger

  def initialize(maid, path, options = {}, &rules)
    @maid = maid
    if options.nil? 
      @lazy = true
      @options = { wait_for_delay: 10, 
                   ignore: Maid::Downloading.downloading_file_regexps }
    else
      @lazy = options.delete(:lazy) { |key| true }
      @options = options
    end
    @logger = maid.logger # TODO: Maybe it's better to create seperate loggers?
    @path = File.expand_path(path)
    initialize_rules(&rules)
  end

  def run
    unless rules.empty?
      @listener = Listen.to(path, @options) do |modified, added, removed|
        if !@lazy || added.any? || removed.any?
          follow_rules(modified, added, removed)
        end
      end
      @listener.start
    end
  end

  def stop
    @listener.stop
  end

  def join
    @listener.thread.join unless @listener.nil? || @listener.paused?
  end
end
