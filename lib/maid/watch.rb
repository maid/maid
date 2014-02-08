require 'listen'
class Maid::Watch
  include Maid::RuleContainer
  
  attr_reader :path, :listener, :logger
  
  def initialize(maid, path, &rules)
    @maid = maid
    @logger = maid.logger # TODO: Maybe it's better to create seperate loggers?
    @path = File.expand_path(path)
    initialize_rules(&rules)
  end

  def run
    unless rules.empty?
      @listener = Listen.to(path) { follow_rules }
      @listener.start
    end
  end
  
  def join
    @listener.thread.join unless @listener.nil? || @listener.paused?
  end
end
