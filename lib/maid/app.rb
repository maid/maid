require 'fileutils'

require 'thor'

class Maid::App < Thor
  check_unknown_options!
  default_task 'introduction'

  desc 'introduction', 'Become aquainted with maid'
  def introduction
    say <<EOF
#{Maid::UserAgent.short}
#{'=' * Maid::UserAgent.short.length}

#{Maid::SUMMARY}

  * Tutorial: https://github.com/benjaminoakes/maid#tutorial
  * Community & examples: https://github.com/benjaminoakes/maid/wiki
  * Documentation: http://www.rubydoc.info/gems/maid/#{Maid::VERSION}/Maid/Tools

For more information, run "maid help".
EOF
  end

  def self.sample_rules_path
    File.join(File.dirname(Maid::Maid::DEFAULTS[:rules_path]), 'rules.sample.rb')
  end

  desc 'clean', 'Clean based on rules'
  method_option :rules,   :type => :string,  :aliases => %w(-r)
  method_option :noop,    :type => :boolean, :aliases => %w(-n --dry-run)
  method_option :force,   :type => :boolean, :aliases => %w(-f)
  method_option :silent,  :type => :boolean, :aliases => %w(-s)
  def clean
    maid = Maid::Maid.new(maid_options(options))

    unless options.noop? || options.force?
      warn 'Running "maid clean" without a flag is deprecated.  Please use "maid clean --noop" or "maid clean --force".'
    end

    if Maid::TrashMigration.needed?
      migrate_trash
      return
    end

    unless options.silent? || options.noop?
      say "Logging actions to #{ maid.log_device.inspect }"
    end

    maid.load_rules
    maid.clean
  end

  desc 'version', 'Print version information (optionally: system info)'
  method_option :long, :type => :boolean, :aliases => %w(-l)
  def version
    if options.long?
      say Maid::UserAgent.value
    else
      say Maid::VERSION
    end
  end

  # Since this happens a lot by mistake
  map '--version' => :version

  desc 'sample', "Create sample rules at #{ self.sample_rules_path }"
  def sample
    path = self.class.sample_rules_path

    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w').puts(File.read(File.join(File.dirname(__FILE__), 'rules.sample.rb')))

    say "Sample rules created at #{ path.inspect }", :green
  end
  
  desc 'daemon', 'Runs the watch/repeat rules in a daemon'
  method_option :rules,   :type => :string,  :aliases => %w(-r)
  method_option :silent,  :type => :boolean, :aliases => %w(-s)
  def daemon
    maid = Maid::Maid.new(maid_options(options))
    
    if Maid::TrashMigration.needed?
      migrate_trash
      return
    end

    unless options.silent?
      say "Logging actions to #{ maid.log_device.inspect }"
    end
    
    maid.load_rules
    maid.daemonize
  end

  desc 'logs', 'Manages logs written by maid'
  method_option :path, :type => :boolean, :aliases => %w(-p)
  method_option :tail, :type => :boolean, :aliases => %w(-t)
  def logs
    maid = Maid::Maid.new(maid_options(options))

    if options.path?
      say maid.log_device
    else
      unless File.readable?(maid.log_device)
        error "Log file #{maid.log_device} does not exist."
      else
        if options.tail?
          system("tail -f #{maid.log_device}")
        else
          say `tail #{maid.log_device}`
        end
      end
    end
  end

  no_tasks do
    def maid_options(options)
      h = {}

      if options['noop']
        # You're testing, so a simple log goes to STDOUT and no actions are taken
        h[:file_options] = { :noop => true }

        unless options['silent']
          h[:logger] = false
          h[:log_device] = STDOUT
          h[:log_formatter] = lambda { |_, _, _, msg| "#{ msg }\n" }
        end
      end

      if options['rules']
        h[:rules_path] = options['rules']
      end

      h
    end
  end

  private

  # Migrate trash to correct directory on Linux due to a configuration bug in previous releases.
  def migrate_trash
    migration = Maid::TrashMigration
    banner('Trash Migration', :yellow)

    say <<-EOF

You are using Linux and have a "~/.Trash" directory.  If you used Maid 0.1.2 or earlier, that directory may exist because Maid incorrectly moved trash files there.

But no worries.  Maid can migrate those files to the correct place.

    EOF

    response = ask("Would you like Maid to move the files in #{ migration.incorrect_trash.inspect } to #{ migration.correct_trash.inspect }?", :limited_to => %w(Y N))

    case response
    when 'Y'
      say('')
      say('Migrating trash...')

      migration.perform

      say('Migrated.  See the Maid log for details.')
    when 'N'
      say <<-EOF

Running Maid again will continue to give this warning until #{ migration.incorrect_trash.inspect } no longer exists, or the environment variable MAID_NO_MIGRATE_TRASH has a value.

Exiting...
      EOF

      exit -1
    else
      raise "Reached 'impossible' case (response: #{ response.inspect })"
    end
  end

  def banner(text, color = nil)
    say(text, color)
    say('-' * text.length, color)
  end
end
