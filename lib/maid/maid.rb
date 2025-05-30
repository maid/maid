require 'fileutils'
require 'xdg'

# Maid cleans up according to the given rules, logging what it does.
#
# TODO: Rename to something less ambiguous, e.g. "cleaning agent", "cleaner", "vacuum", etc.  Having this class within
# the `Maid` module makes things confusing.
class Maid::Maid
  include Maid::RuleContainer
  DEFAULTS = {
    log_device: File.expand_path('~/.maid/maid.log'),
    logger: ::Maid::Logger,

    rules_path: File.expand_path('~/.maid/rules.rb'),
    file_options: { noop: false }, # for `FileUtils`
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
    options = DEFAULTS.merge(options.reject { |_k, v| v.nil? })

    @logger = options[:logger].new(device: options[:log_device])

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
    unless @log_device.is_a?(IO)
      @logger.info "v#{Maid::VERSION}"
      @logger.info 'Started'
    end

    follow_rules

    return if @log_device.is_a?(IO)

    @logger.info 'Finished'
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
    warn e.message
  end

  def watch(path, options = {}, &)
    full_path = File.expand_path(path)

    unless File.directory?(full_path)
      message = "#{full_path} cannot be a file and it must exist in order to watch it"

      warn(message)
      raise message
    end

    @watches << ::Maid::Watch.new(self, path, options, &)
  end

  def repeat(timestring, options = {}, &)
    @repeats << ::Maid::Repeat.new(self, timestring, options, &)
  end

  # Daemonizes the process by starting all watches and repeats and joining
  # the threads of the schedulers/watchers
  def daemonize
    if @watches.empty? && @repeats.empty?
      warn 'Cannot run daemon. Nothing to watch or repeat.'
    else
      all = @watches + @repeats
      all.each(&:run)
      trap('SIGINT') do
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
  def cmd(command) # :nodoc:
    raise NotImplementedError, "Unsupported system command: #{command.inspect}" unless supported_command?(command)

    `#{command}`
  end

  private

  # Does the OS support this command?
  def supported_command?(command) # :nodoc:
    @@supported_commands ||= {}

    command_name = command.strip.split(/\s+/)[0]
    supported = @@supported_commands[command_name]
    # TODO: Instead of using `which`, use an alternative listed at:
    #
    #     http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
    @@supported_commands[command_name] = supported || !`which #{command_name}`.empty?
  end

  def default_trash_path
    # TODO: Refactor module declaration so this can be `Platform`
    if Maid::Platform.linux?
      # See the [FreeDesktop.org Trash specification](https://archive.is/cXir4)
      path = "#{XDG['DATA_HOME']}/Trash/files"
    elsif Maid::Platform.osx?
      path = File.expand_path('~/.Trash')
    else
      raise NotImplementedError, "Unknown default trash path (unsupported host OS: #{Maid::Platform.host_os.inspect})"
    end

    "#{path}/"
  end
end
