require 'rufus-scheduler'
class Maid::Repeat
  include Maid::RuleContainer

  attr_reader :timestring, :scheduler, :logger

  def initialize(maid, timestring, options = {}, &)
    @maid = maid
    @logger = maid.logger # TODO: Maybe it's better to create seperate loggers?
    @scheduler = Rufus::Scheduler.singleton
    @timestring = timestring
    @options = options
    initialize_rules(&)
  end

  def run
    return if rules.empty?

    @scheduler.repeat(timestring, @options) { follow_rules }
  end

  def stop
    @scheduler.shutdown(:join) # Join the work threads
  end
end
