require 'rubygems'
require 'thor'

class Maid::App < Thor
  check_unknown_options!
  default_task 'clean'

  desc 'clean', 'Clean based on rules'
  method_option :rules,  :type => :string,  :aliases => %w[-r]
  method_option :noop,   :type => :boolean, :aliases => %w[-n --dry-run]
  method_option :silent, :type => :boolean, :aliases => %w[-s]
  def clean
    maid = Maid::Maid.new(maid_options(options))
    unless options.silent? || options.noop?
      say "Logging actions to #{maid.log_path.inspect}"
    end
    maid.clean
  end

  desc 'version', 'Print version number'
  def version
    say Maid::VERSION
  end

  no_tasks do
    def maid_options(options)
      h = {}

      if options['noop']
        # You're testing, so a simple log goes to STDOUT and no actions are taken
        h[:file_options] = {:noop => true}
        h[:log_path] = STDOUT
        h[:log_formatter] = lambda { |_, _, _, msg| "#{msg}\n" }
      end

      if options['rules']
        h[:rules_path] = options['rules']
      end

      h
    end
  end
end
