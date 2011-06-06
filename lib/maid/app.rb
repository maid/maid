require 'fileutils'

require 'rubygems'
require 'thor'

class Maid::App < Thor
  check_unknown_options!
  default_task 'clean'

  def self.sample_rules_path
    Maid::Maid::DEFAULTS[:rules_path] + '.sample'
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
    File.open(path, 'w').puts <<-EOF
# Sample Maid rules file -- a sampling to get you started.
#
# To use, remove ".sample" from the filename.  Test using:
#
#     maid -n
#
# For more help on Maid:
#
#   * Run `maid help`
#   * Read the README at http://github.com/benjaminoakes/maid
#   * For more DSL helper methods, please see the documentation of Maid::Tools.
#   * Come up with some cool tools of your own?  Fork, make your changes, and send me a pull request on GitHub!
#   * Ask me a question over email (hello@benjaminoakes.com) or twitter (@benjaminoakes)
#
Maid.rules do
  rule 'MP3s likely to be music' do
    dir('~/Downloads/*.mp3').each do |path|
      if duration_s(path) > 30.0
        move(path, '~/Music/iTunes/iTunes Media/Automatically Add to iTunes/')
      end
    end
  end

  rule 'Old files downloaded while developing/testing' do
    dir('~/Downloads/*').each do |path|
      if downloaded_from(path).any? {|u| u.match 'http://localhost' || u.match('http://staging.yourcompany.com') } && 1.week.since?(last_accessed(path))
        trash(path)
      end
    end
  end

  rule 'Linux ISOs, etc' do
    dir('~/Downloads/*.iso').each { |p| trash p }
  end

  rule 'Linux applications in Debian packages' do
    dir('~/Downloads/*.deb').each { |p| trash p }
  end

  rule 'Mac OS X applications in disk images' do
    dir('~/Downloads/*.dmg').each { |p| trash p }
  end

  rule 'Mac OS X applications in zip files' do
    dir('~/Downloads/*.zip').select do |path|
      candidates = zipfile_contents(path)
      candidates.any? { |c| c.match(/\.app$/) }
    end.each { |p| trash p }
  end

  rule 'Misc Screenshots' do
    dir('~/Desktop/Screen shot *').each do |path|
      if 1.week.since?(last_accessed(path))
        move(path, '~/Documents/Misc Screenshots/')
      end
    end
  end

  # Add your own rules here.
end
    EOF

    puts "Sample rules created at #{path.inspect}"
  end

  no_tasks do
    def maid_options(options)
      h = {}

      if options['noop']
        # You're testing, so a simple log goes to STDOUT and no actions are taken
        h[:file_options] = {:noop => true}
        h[:log_device] = STDOUT
        h[:log_formatter] = lambda { |_, _, _, msg| "#{msg}\n" }
      end

      if options['rules']
        h[:rules_path] = options['rules']
      end

      h
    end
  end
end
