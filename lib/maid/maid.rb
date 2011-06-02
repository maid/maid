require 'fileutils'
require 'logger'

# Maid cleans up according to the given rules, logging what it does.
class Maid::Maid
  DEFAULTS = {
    :progname     => 'Maid',
    :log_path     => File.expand_path('~/.maid/maid.log'),
    :rules_path   => File.expand_path('~/.maid/rules.rb'),
    :trash_path   => File.expand_path('~/.Trash'),
    :file_options => {:noop => true}, # for FileUtils
  }.freeze

  attr_reader :file_options, :log_path, :rules, :rules_path, :trash_path
  include ::Maid::Tools

  # Make a new Maid, setting up paths for the log and trash.
  # 
  # Sane defaults for a log and trash path are set for Mac OS X, but they can easily be overridden like so:
  # 
  #   Maid::Maid.new(:log_path => '/home/username/log/maid.log', :trash_path => '/home/username/.local/share/Trash/files/')
  # 
  def initialize(options = {})
    options = DEFAULTS.merge(options.reject { |k, v| v.nil? })

    @log_path = options[:log_path]
    FileUtils.mkdir_p(File.dirname(@log_path)) unless @log_path.kind_of?(IO)
    @logger = Logger.new(@log_path)
    @logger.progname = options[:progname]
    @logger.formatter = options[:log_formatter] if options[:log_formatter]

    @rules_path = options[:rules_path]
    @trash_path = options[:trash_path]
    @file_options = options[:file_options]

    @rules = []
  end
  
  # Start cleaning, based on the rules defined at rules_path.
  def clean
    @logger.info "v#{Maid::VERSION}"
    @logger.info 'Started'
    add_rules(@rules_path)
    follow_rules
    @logger.info 'Finished'
  end

  # Add the rules at path.
  def add_rules(path)
    Maid.with_instance(self) do
      # Using 'Kernel' here to help with testability
      # Kernel.load must be used for non-".rb" files to be required, it seems.
      Kernel.load(path)
    end
  rescue LoadError => e
    STDERR.puts e.message
  end

  # Register a rule with a description and instructions (lambda function).
  def rule(description, &instructions)
    @rules << ::Maid::Rule.new(description, instructions)
  end

  # Follow all registered rules.
  def follow_rules
    @rules.each do |rule|
      @logger.info("Rule: #{rule.description}")
      rule.follow
    end
  end

  # Run a shell command.
  #--
  # Delegates to Kernel.`.  Made primarily for testing other commands and some error handling.
  def cmd(command) #:nodoc:
    if supported_command?(command)
      %x(#{command})
    else
      STDERR.puts "Unsupported command: #{command.inspect}"
    end
  end

private

  # Does the OS support this command?
  def supported_command?(command) #:nodoc:
    @@supported_commands ||= {}

    command_name = command.strip.split(/\s+/)[0]
    supported = @@supported_commands[command_name]
    @@supported_commands[command_name] = supported ? supported : !%x(which #{command_name}).empty?
  end
end
