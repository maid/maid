require 'fileutils'

require 'rubygems'
require 'thor'

class Maid::App < Thor
  check_unknown_options!
  default_task 'help'

  def self.sample_rules_path
    File.join(File.dirname(Maid::Maid::DEFAULTS[:rules_path]), 'rules.sample.rb')
  end

  desc 'clean', 'Clean based on rules'
  method_option :rules,  :type => :string,  :aliases => %w[-r]
  method_option :noop,   :type => :boolean, :aliases => %w[-n --dry-run]
  method_option :silent, :type => :boolean, :aliases => %w[-s]
  def clean
    maid = Maid::Maid.new(maid_options(options))
    unless options.silent? || options.noop?
      say "Logging actions to #{maid.log_device.inspect}"
    end

    maid.load_rules
    maid.clean
  end

  desc 'version', 'Print version number'
  def version
    say Maid::VERSION
  end

  desc 'sample', "Create sample rules at #{self.sample_rules_path}"
  def sample
    path = self.class.sample_rules_path

    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w').puts(File.read(File.join(File.dirname(__FILE__), 'rules.sample.rb')))

    say "Sample rules created at #{path.inspect}", :green
  end

  private

  def maid_options(options)
    h = {}

    if options['noop']
      # You're testing, so a simple log goes to STDOUT and no actions are taken
      h[:file_options] = {:noop => true}

      unless options['silent']
        h[:logger] = false
        h[:log_device] = STDOUT
        h[:log_formatter] = lambda { |_, _, _, msg| "#{msg}\n" }
      end
    end

    if options['rules']
      h[:rules_path] = options['rules']
    end

    h
  end
end
