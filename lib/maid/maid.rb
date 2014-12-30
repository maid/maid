require 'fileutils'
require 'logger'
require 'xdg'

# Maid cleans up according to the given rules, logging what it does.
#
# TODO: Rename to something less ambiguous, e.g. "cleaning agent", "cleaner", "vacuum", etc.  Having this class within
# the `Maid` module makes things confusing.
class Maid::Maid
  include Maid::RuleContainer
  DEFAULTS = {
    :progname     => 'Maid',

    :log_device   => File.expand_path('~/.maid/maid.log'),
    # We don't want the log files to grow without check, but 50 MB doesn't seem too bad.  (We're going with a larger size just for safety right now.)
    :log_shift_age  => 5,
    :log_shift_size => 10 * 1_048_576, # 10 * 1 MB

    :rules_path   => File.expand_path('~/.maid/rules.rb'),
    :file_options => { :noop => false }, # for `FileUtils`
  }.freeze

  attr_reader :file_options, :logger, :log_device, :rules_path, :trash_path, :watches, :repeats
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
      @logger = Logger.new(@log_device, options[:log_shift_age], options[:log_shift_size])
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

    @watches = []
    @repeats = []
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

  def watch(path, options = {}, &rules)
    @watches << ::Maid::Watch.new(self, path, options, &rules)
  end

  def repeat(timestring, &rules)
    @repeats << ::Maid::Repeat.new(self, timestring, &rules)
  end

  # Daemonizes the process by starting all watches and repeats and joining
  # the threads of the schedulers/watchers
  def daemonize
    if @watches.empty? && @repeats.empty?
      STDERR.puts 'Cannot run daemon. Nothing to watch or repeat.'
    else
      all = @watches + @repeats
      all.each(&:run)
      trap("SIGINT") do
        # Running in a thread fixes celluloid ThreadError
        Thread.new do
          all.each(&:stop)
          exit!
        end.join
      end
      sleep
    end
  end

  # Run a shell command.
  #--
  # Delegates to `Kernel.\``.  Made primarily for testing other commands and some error handling.
  def cmd(command) #:nodoc:
    if supported_command?(command)
      %x(#{ command })
    else
      raise NotImplementedError, "Unsupported system command: #{ command.inspect }"
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
