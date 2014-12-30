require 'listen'
class Maid::Watch
  include Maid::RuleContainer

  attr_reader :path, :listener, :logger

  def initialize(maid, path, options = {}, &rules)
    @maid = maid
    @options = options
    @logger = maid.logger # TODO: Maybe it's better to create seperate loggers?
    @path = File.expand_path(path)
    initialize_rules(&rules)
  end

  def run
    unless rules.empty?
      @listener = Listen.to(path, @options) do |modified, added, removed|
        follow_rules(modified, added, removed)
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
