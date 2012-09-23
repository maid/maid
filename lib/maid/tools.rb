require 'fileutils'
require 'find'
require 'time'

# Collection of utility methods included in Maid::Maid (and thus available in the rules DSL).
#
# In general, all paths are automatically expanded (e.g. '~/Downloads/foo.zip' becomes '/home/username/Downloads/foo.zip').
#
# Some methods are not available on all platforms.  An <tt>ArgumentError</tt> is raised when a command is not available.  See tags: [Mac OS X]
module Maid::Tools
  include Deprecated

  # Move from <tt>from</tt> to <tt>to</tt>.
  #
  # The path is not moved if a file already exists at the destination with the same name.  A warning is logged instead.
  #
  # This method delegates to FileUtils.  The instance-level <tt>file_options</tt> hash is passed to control the <tt>:noop</tt> option.
  #
  #   move('~/Downloads/foo.zip', '~/Archive/Software/Mac OS X/')
  # 
  # This method can handle multiple from paths.
  #
  #   move(['~/Downloads/foo.zip', '~/Downloads/bar.zip'], '~/Archive/Software/Mac OS X/')
  #   move(dir('~/Downloads/*.zip'), '~/Archive/Software/Mac OS X/')
  def move(froms, to)
    Array(froms).each do |from|
      from = File.expand_path(from)
      to = File.expand_path(to)
      target = File.join(to, File.basename(from))

      unless File.exist?(target)
        @logger.info "mv #{from.inspect} #{to.inspect}"
        FileUtils.mv(from, to, @file_options)
      else
        @logger.warn "skipping #{from.inspect} because #{target.inspect} already exists"
      end
    end
  end

  # Move the given path to the trash (as set by <tt>trash_path</tt>).
  #
  # The path is moved if a file already exists in the trash with the same name.  However, the current date and time is appended to the filename.
  # 
  # Options:
  #
  # - :remove_over => Fixnum (e.g. 1.gigabyte, 1024.megabytes)
  #     Remove files over the given size rather than moving to the trash.
  #     See also Maid::NumericExtensions::SizeToKb
  #
  #   trash('~/Downloads/foo.zip')
  # 
  # This method can also handle multiple paths.
  #
  #   trash(['~/Downloads/foo.zip', '~/Downloads/bar.zip'])
  #   trash(dir('~/Downloads/*.zip'))
  def trash(paths, options = {})
    Array(paths).each do |path|
      target = File.join(@trash_path, File.basename(path))
      safe_trash_path = File.join(@trash_path, "#{File.basename(path)} #{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}")

      if options[:remove_over] &&
          File.exist?(path) &&
          disk_usage(path) > options[:remove_over]
        remove(path)
      end

      if File.exist?(path)
        if File.exist?(target)
          move(path, safe_trash_path)
        else
          move(path, @trash_path)
        end
      end
    end
  end

  # Remove the given path recursively.
  # 
  # Options:
  #
  # - :force => boolean
  # - :secure => boolean (See FileUtils.remove_entry_secure for further details)
  #
  #   remove('~/Downloads/foo.zip')
  #
  # This method can handle multiple remove paths.
  #
  #   remove(['~/Downloads/foo.zip', '~/Downloads/bar.zip'])
  #   remove(dir('~/Downloads/*.zip'))
  def remove(paths, options = {})
    Array(paths).each do |path|
      path = File.expand_path(path)
      options = @file_options.merge(options)

      @logger.info "Removing #{path.inspect}"
      FileUtils.rm_r(path,options)
    end
  end

  # Give all files matching the given glob.
  #
  #   dir('~/Downloads/*.zip')
  def dir(glob)
    Dir[File.expand_path(glob)]
  end

  # Creates a directory and all its parent directories.
  #
  # Options:
  #
  # - :mode,  the symbolic and absolute mode both can be used.
  #           eg. 0700, 'u=wr,go=rr'
  #
  #   mkdir('~/Downloads/Music/Pink.Floyd/', :mode => 0644)
  def mkdir(path, options = {})
    FileUtils.mkdir_p(File.expand_path(path), options)
  end

  # Find matching files, akin to the Unix utility <tt>find</tt>.
  #
  # If no block is given, it will return an array.
  #
  #   find '~/Downloads/' # => [...]
  #
  # or delegates to Find.find.
  #
  #   find '~/Downloads/' do |path|
  #     # ...
  #   end
  #
  def find(path, &block)
    expanded_path = File.expand_path(path)

    if block.nil?
      files = []
      Find.find(expanded_path) { |file_path| files << file_path }
      files
    else
      Find.find(expanded_path, &block)
    end
  end

  # [Mac OS X] Use Spotlight to locate all files matching the given filename.
  #
  #   locate('foo.zip') # => ['/a/foo.zip', '/b/foo.zip']
  #--
  # TODO use `locate` elsewhere -- it isn't available by default on OS X starting with OS X Leopard.
  def locate(name)
    cmd("mdfind -name #{name.inspect}").split("\n")
  end

  # [Mac OS X] Use Spotlight metadata to determine the site from which a file was downloaded.
  #
  #   downloaded_from('foo.zip') # => ['http://www.site.com/foo.zip', 'http://www.site.com/']
  def downloaded_from(path)
    raw = cmd("mdls -raw -name kMDItemWhereFroms #{path.inspect}")
    clean = raw[1, raw.length - 2]
    clean.split(/,\s+/).map { |s| t = s.strip; t[1, t.length - 2] }
  end

  # [Mac OS X] Use Spotlight metadata to determine audio length.
  #
  #   duration_s('foo.mp3') # => 235.705
  def duration_s(path)
    cmd("mdls -raw -name kMDItemDurationSeconds #{path.inspect}").to_f
  end

  # Inspect the contents of a .zip file.
  #
  #   zipfile_contents('foo.zip') # => ['foo/foo.exe', 'foo/README.txt']
  def zipfile_contents(path)
    raw = cmd("unzip -Z1 #{path.inspect}")
    raw.split("\n")
  end

  # Calculate disk usage of a given path.
  #
  # FIXME: This reports in kilobytes, but should probably report in bytes.
  #
  #   disk_usage('foo.zip') # => 136
  def disk_usage(path)
    raw = cmd("du -s #{path.inspect}")
    usage_kb = raw.split(/\s+/).first.to_i
   
    if usage_kb.zero?
      raise "Stopping pessimistically because of unexpected value from du (#{raw.inspect})"
    else
      usage_kb
    end
  end

  # In Unix speak, "ctime".
  #
  #   created_at('foo.zip') # => Sat Apr 09 10:50:01 -0400 2011
  def created_at(path)
    File.ctime(File.expand_path(path))
  end

  # In Unix speak, "atime".
  #
  #   accessed_at('foo.zip') # => Sat Apr 09 10:50:01 -0400 2011
  def accessed_at(path)
    File.atime(File.expand_path(path))
  end

  alias :last_accessed :accessed_at
  deprecated :last_accessed, :accessed_at

  # In Unix speak, "mtime".
  #
  #   modified_at('foo.zip') # => Sat Apr 09 10:50:01 -0400 2011
  def modified_at(path)
    File.mtime(File.expand_path(path))
  end

  # Pulls and pushes the given git repository.
  #
  # Since this is deprecated, you might also be interested in SparkleShare (http://sparkleshare.org/), a great git-based file syncronization project.
  #
  #   git_piston('~/code/projectname')
  #
  # @deprecated
  def git_piston(path)
    full_path = File.expand_path(path)
    stdout = cmd("cd #{full_path.inspect} && git pull && git push 2>&1")
    @logger.info "Fired git piston on #{full_path.inspect}.  STDOUT:\n\n#{stdout}"
  end

  deprecated :git_piston, 'SparkleShare (http://sparkleshare.org/)'

  # [Rsync] Simple sync of two files/folders using rsync.
  #
  # See rsync man page for a detailed description.
  # 
  # Options:
  #
  # - :delete => boolean
  # - :verbose => boolean
  # - :archive => boolean (default true)
  # - :update => boolean (default true)
  # - :exclude => string EXE :exclude => ".git" or :exclude => [".git", ".rvmrc"]
  # - :prune_empty => boolean
  #
  #   sync('~/music', '/backup/music')
  def sync(from, to, options = {})
    # expand path removes trailing slash
    # cannot use str[-1] due to ruby 1.8.7 restriction
    from = File.expand_path(from) + (from.end_with?('/') ? '/' : '')
    to = File.expand_path(to) + (to.end_with?('/') ? '/' : '')
    # default options
    options = { :archive => true, :update => true }.merge(options)
    ops = []
    ops << '-a' if options[:archive]
    ops << '-v' if options[:verbose]
    ops << '-u' if options[:update]
    ops << '-m' if options[:prune_empty]
    ops << '-n' if @file_options[:noop]

    Array(options[:exclude]).each do |path|
      ops << "--exclude=#{path.inspect}"
    end

    ops << '--delete' if options[:delete]
    stdout = cmd("rsync #{ops.join(' ')} #{from.inspect} #{to.inspect} 2>&1")
    @logger.info "Fired sync from #{from.inspect} to #{to.inspect}.  STDOUT:\n\n#{stdout}"
  end
end
