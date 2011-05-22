require 'fileutils'
require 'logger'

# Maid cleans up according to the given rules, logging what it does.
class Maid::Maid
  DEFAULTS = {
    :progname   => 'Maid',
    :log_path   => File.expand_path('~/.maid/maid.log'),
    :rules_path => File.expand_path('~/.maid/rules.rb'),
    :trash_path => File.expand_path('~/.Trash'),
  }.freeze

  attr_reader :trash_path

  # Make a new Maid, setting up paths for the log and trash.
  # 
  # Sane defaults for a log and trash path are set for Mac OS X, but they can easily be overridden like so:
  # 
  #   Maid.new(:log_path => '/home/username/log/maid.log', :trash_path => '/home/username/.local/share/Trash/files/')
  # 
  def initialize(options = {})
    options = DEFAULTS.merge(options)

    FileUtils.mkdir_p(File.dirname(options[:log_path]))
    @logger = Logger.new(options[:log_path])
    @logger.progname = options[:progname]

    @trash_path = options[:trash_path]
  end
  
  # Start cleaning, based on the rules defined at rules_path.
  def clean(rules_path = DEFAULTS[:rules_path])
    @logger.info 'Started'
    process_rules(rules_path)
    @logger.info 'Finished'
  end

  # Process the rules at path.
  def process_rules(path)
    # Using 'Kernel' here to help with testability
    Kernel.require path
  end
end
