require 'fileutils'
require 'logger'

require 'xdg'

# Maid cleans up according to the given rules, logging what it does.
#
# TODO: Rename to something less ambiguous, e.g. "cleaning agent", "cleaner", "vacuum", etc.  Having this class within
# the `Maid` module makes things confusing.
class Maid::Maid
  DEFAULTS = {
    :progname     => 'Maid',
    :log_device   => File.expand_path('~/.maid/maid.log'),
    :rules_path   => File.expand_path('~/.maid/rules.rb'),
    :file_options => { :noop => false }, # for `FileUtils`
  }.freeze

  attr_reader :file_options, :logger, :log_device, :rules, :rules_path, :trash_path
  include ::Maid::Tools

  # Make a new Maid, setting up paths for the log and trash.
  # 
  # Sane defaults for a log and trash path are set for Mac OS X, but they can easily be overridden like so:
  # 
  #     Maid::Maid.new(:log_device => '/home/username/log/maid.log', :trash_path => '/home/username/my_trash')
  # 
  def initialize(options = {})
    options = DEFAULTS.merge(options.reject { |k, v| v.nil? })

    # TODO: Refactor and simplify (see also https://github.com/benjaminoakes/maid/pull/48#discussion_r1683942)
    @logger = unless options[:logger]
      @log_device = options[:log_device]
      FileUtils.mkdir_p(File.dirname(@log_device)) unless @log_device.kind_of?(IO)
      Logger.new(@log_device)
    else
      options[:logger]
    end

    @logger.progname  = options[:progname]
    @logger.formatter = options[:log_formatter] if options[:log_formatter]

    @rules_path   = options[:rules_path]
    @trash_path   = options[:trash_path] || default_trash_path
    @file_options = options[:file_options]

    # Just in case they aren't there...
    FileUtils.mkdir_p(File.expand_path('~/.maid'))
    FileUtils.mkdir_p(@trash_path)

    @rules = []
  end
  
  # Start cleaning, based on the rules defined at rules_path.
  def clean
    unless @log_device.kind_of?(IO)
      @logger.info "v#{ Maid::VERSION }"
      @logger.info 'Started'
    end

    follow_rules

    unless @log_device.kind_of?(IO)
      @logger.info 'Finished'
    end
  end

  # Add the rules at rules_path.
  def load_rules
    path = @rules_path

    Maid.with_instance(self) do
      # Using `Kernel` here to help with testability.
      #
      # `Kernel.load` must be used for non-".rb" files to be required, it seems.
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
      @logger.info("Rule: #{ rule.description }")
      rule.follow
    end
  end

  # Run a shell command.
  #--
  # Delegates to `Kernel.\``.  Made primarily for testing other commands and some error handling.
  def cmd(command) #:nodoc:
    if supported_command?(command)
      %x(#{ command })
    else
      raise ArgumentError, "Unsupported system command: #{ command.inspect }"
    end
  end

  private

  # Does the OS support this command?
  def supported_command?(command) #:nodoc:
    @@supported_commands ||= {}

    command_name = command.strip.split(/\s+/)[0]
    supported = @@supported_commands[command_name]
    # TODO: Instead of using `which`, use an alternative listed at:
    #
    #     http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
    @@supported_commands[command_name] = supported ? supported : !%x(which #{ command_name }).empty?
  end

  def default_trash_path
    # TODO: Refactor module declaration so this can be `Platform`
    if Maid::Platform.linux?
      # See the [FreeDesktop.org Trash specification](http://www.ramendik.ru/docs/trashspec.html)
      path = "#{ XDG['DATA_HOME'] }/Trash/files"
    elsif Maid::Platform.osx?
      path = File.expand_path('~/.Trash')
    else
      raise NotImplementedError, "Unknown default trash path (unsupported host OS: #{ Maid::Platform.host_os.inspect })"
    end

    "#{ path }/"
  end
end
