require 'fileutils'
require 'find'
require 'time'

# These "tools" are methods available in the Maid DSL.
#
# In general, methods are expected to:
#
# * Automatically expand paths (that is, `'~/Downloads/foo.zip'` becomes `'/home/username/Downloads/foo.zip'`)
# * Respect the `noop` (`dry-run`) option if it is set
#
# Some methods are not available on all platforms.  An `ArgumentError` is raised when a command is not available.  See
# tags such as: [Mac OS X]
module Maid::Tools
  include Deprecated

  # Move from `sources` to `destination`
  #
  # The path is not moved if a file already exists at the destination with the same name.  A warning is logged instead.
  #
  # ## Examples
  #
  # Single path:
  #
  #     move('~/Downloads/foo.zip', '~/Archive/Software/Mac OS X/')
  # 
  # Multiple paths:
  #
  #     move(['~/Downloads/foo.zip', '~/Downloads/bar.zip'], '~/Archive/Software/Mac OS X/')
  #     move(dir('~/Downloads/*.zip'), '~/Archive/Software/Mac OS X/')
  def move(sources, destination)
    destination = expand(destination)

    expand_all(sources).each do |source|
      target = File.join(destination, File.basename(source))

      unless File.exist?(target)
        log("mv #{ source.inspect } #{ destination.inspect }")
        FileUtils.mv(source, destination, @file_options)
      else
        warn("skipping #{ source.inspect } because #{ target.inspect } already exists")
      end
    end
  end

  # Move the given paths to the user's trash.
  #
  # The path is still moved if a file already exists in the trash with the same name.  However, the current date and
  # time is appended to the filename.
  # 
  # **Note:** the OS-native "restore" or "put back" functionality for trashed files is not currently supported.  (See
  # [issue #63](https://github.com/benjaminoakes/maid/issues/63).)  However, they can be restored manually, and the Maid
  # log can help assist with this.
  # 
  # ## Options
  #
  # `:remove_over => Fixnum` (e.g. `1.gigabyte`, `1024.megabytes`)
  #
  # Delete files over the given size rather than moving to the trash.
  #
  # See also `Maid::NumericExtensions::SizeToKb`
  #
  # ## Examples
  #
  # Single path:
  #
  #     trash('~/Downloads/foo.zip')
  # 
  # Multiple paths:
  #
  #     trash(['~/Downloads/foo.zip', '~/Downloads/bar.zip'])
  #     trash(dir('~/Downloads/*.zip'))
  def trash(paths, options = {})
    # ## Implementation Notes
    #
    # Trashing files correctly is surprisingly hard.  What Maid ends up doing is one the easiest, most foolproof
    # solutions:  moving the file.
    #
    # Unfortunately, that means it's not possile to restore files automatically in OSX or Ubuntu.  The previous location
    # of the file is lost.
    #
    # OSX support depends on AppleScript or would require a not-yet-written C extension to interface with the OS.  The
    # AppleScript solution is less than ideal: the user has to be logged in, Finder has to be running, and it makes the
    # "trash can sound" every time a file is moved.
    #
    # Ubuntu makes it easy to implement, and there's a Python library for doing so (see `trash-cli`).  However, there's
    # not a Ruby equivalent yet.

    expand_all(paths).each do |path|
      target = File.join(@trash_path, File.basename(path))
      safe_trash_path = File.join(@trash_path, "#{ File.basename(path) } #{ Time.now.strftime('%Y-%m-%d-%H-%M-%S') }")

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

  # Delete the files at the given path recursively.
  #
  # **NOTE**: In most cases, `trash` is a safer choice, since the files will be recoverable by retreiving them from the trash.  Once you delete a file using `remove`, it's gone!  Please use `trash` whenever possible and only use `remove` when necessary.
  # 
  # ## Options
  #
  # `:force => boolean`
  #
  # Force deletion (no error is raised if the file does not exist).
  #
  # `:secure => boolean`
  #
  # Infrequently needed. See [`FileUtils.remove_entry_secure`][fures]
  #
  # ## Examples
  #
  # Single path:
  #
  #     remove('~/Downloads/foo.zip')
  #
  # Multiple path:
  #
  #     remove(['~/Downloads/foo.zip', '~/Downloads/bar.zip'])
  #     remove(dir('~/Downloads/*.zip'))
  #
  #   [fures]: http://www.ruby-doc.org/stdlib-1.9.3/libdoc/fileutils/rdoc/FileUtils.html#method-c-remove_entry_secure
  def remove(paths, options = {})
    expand_all(paths).each do |path|
      options = @file_options.merge(options)

      log("Removing #{ path.inspect }")
      FileUtils.rm_r(path, options)
    end
  end

  # Give all files matching the given glob.
  #
  # Note that the globs are *not* regexps (they're closer to shell globs).  However, some regexp-like notation can be
  # used, e.g. `?`, `[a-z]`, `{tgz,zip}`.  For more details, see Ruby's documentation on `Dir.glob`.
  #
  # The matches are sorted lexically to aid in readability when using `--dry-run`.
  #
  # ## Examples
  #
  # Single glob:
  #
  #     dir('~/Downloads/*.zip')
  #
  # Specifying multiple extensions succinctly:
  #
  #     dir('~/Downloads/*.{exe,deb,dmg,pkg,rpm}')
  #
  # Multiple glob (both are equivalent):
  #
  #     dir(['~/Downloads/*.zip', '~/Dropbox/*.zip'])
  #     dir(%w(~/Downloads/*.zip ~/Dropbox/*.zip))
  #
  def dir(globs)
    expand_all(globs).
      map { |glob| Dir.glob(glob) }.
      flatten.
      sort
  end

  # Create a directory and all of its parent directories.
  #
  # The path of the created directory is returned, which allows for chaining (see examples).
  #
  # ## Options
  #
  # `:mode`
  #
  # The symbolic and absolute mode can both be used, for example: `0700`, `'u=wr,go=rr'`
  #
  # ## Examples
  #
  # Creating a directory with a specific mode:
  #
  #     mkdir('~/Music/Pink Floyd/', :mode => 0644)
  #
  # Ensuring a directory exists when moving:
  #
  #     move('~/Downloads/Pink Floyd*.mp3', mkdir('~/Music/Pink Floyd/'))
  def mkdir(path, options = {})
    path = expand(path)
    FileUtils.mkdir_p(path, options) # @file_options.merge(options))
    path
  end

  # Find matching files, akin to the Unix utility `find`.
  #
  # If no block is given, it will return an array.  Otherwise, it acts like `Find.find`.
  #
  # ## Examples
  #
  # Without a block:
  #
  #     find('~/Downloads/') # => [...]
  #
  # Recursing with a block:
  #
  #     find('~/Downloads/') do |path|
  #       # ...
  #     end
  #
  def find(path, &block)
    expanded_path = expand(path)

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
  # [Ubuntu] Not currently supported.  See [issue #67](https://github.com/benjaminoakes/maid/issues/67).
  #
  # ## Examples
  #
  #     locate('foo.zip') # => ['/a/foo.zip', '/b/foo.zip']
  def locate(name)
    cmd("mdfind -name #{ name.inspect }").split("\n")
  end

  # [Mac OS X] Use Spotlight metadata to determine the site from which a file was downloaded.
  #
  # ## Examples
  #
  #     downloaded_from('foo.zip') # => ['http://www.site.com/foo.zip', 'http://www.site.com/']
  def downloaded_from(path)
    raw = cmd("mdls -raw -name kMDItemWhereFroms #{ path.inspect }")
    clean = raw[1, raw.length - 2]
    clean.split(/,\s+/).map { |s| t = s.strip; t[1, t.length - 2] }
  end

  # [Mac OS X] Use Spotlight metadata to determine audio length.
  #
  # ## Examples
  #
  #     duration_s('foo.mp3') # => 235.705
  def duration_s(path)
    cmd("mdls -raw -name kMDItemDurationSeconds #{ path.inspect }").to_f
  end

  # List the contents of a zip file.
  #
  # ## Examples
  #
  #     zipfile_contents('foo.zip') # => ['foo/foo.exe', 'foo/README.txt']
  def zipfile_contents(path)
    raw = cmd("unzip -Z1 #{ path.inspect }")
    raw.split("\n")
  end

  # Calculate disk usage of a given path in kilobytes.
  #
  # See also: `Maid::NumericExtensions::SizeToKb`.
  #
  # ## Examples
  #
  #     disk_usage('foo.zip') # => 136
  def disk_usage(path)
    raw = cmd("du -s #{ path.inspect }")
    # FIXME: This reports in kilobytes, but should probably report in bytes.
    usage_kb = raw.split(/\s+/).first.to_i
   
    if usage_kb.zero?
      raise "Stopping pessimistically because of unexpected value from du (#{ raw.inspect })"
    else
      usage_kb
    end
  end

  # Get the creation time of a file.
  #
  # In Unix speak, `ctime`.
  #
  # ## Examples
  #
  #     created_at('foo.zip') # => Sat Apr 09 10:50:01 -0400 2011
  def created_at(path)
    File.ctime(expand(path))
  end

  # Get the time that a file was last accessed.
  #
  # In Unix speak, `atime`.
  #
  # ## Examples
  #
  #     accessed_at('foo.zip') # => Sat Apr 09 10:50:01 -0400 2011
  def accessed_at(path)
    File.atime(expand(path))
  end

  # @deprecated
  #
  # Alias of `accessed_at`.
  def last_accessed(path)
    # Not a normal `alias` so the deprecation notice shows in the docs.
    accessed_at(path)
  end
  deprecated :last_accessed, :accessed_at

  # Get the modification time of a file.
  #
  # In Unix speak, `mtime`.
  #
  # ## Examples
  #
  #     modified_at('foo.zip') # => Sat Apr 09 10:50:01 -0400 2011
  def modified_at(path)
    File.mtime(expand(path))
  end

  # @deprecated
  #
  # Pull and push the `git` repository at the given path.
  #
  # Since this is deprecated, you might also be interested in [SparkleShare](http://sparkleshare.org/), a great
  # `git`-based file syncronization project.
  #
  # ## Examples
  #
  #     git_piston('~/code/projectname')
  def git_piston(path)
    full_path = expand(path)
    stdout = cmd("cd #{full_path.inspect} && git pull && git push 2>&1")
    log("Fired git piston on #{full_path.inspect}.  STDOUT:\n\n#{stdout}")
  end

  deprecated :git_piston, 'SparkleShare (http://sparkleshare.org/)'

  # Simple sync two files/folders using `rsync`.
  #
  # The host OS must provide `rsync`.  See the `rsync` man page for a detailed description.
  #
  #     man rsync
  # 
  # ## Options
  #
  # `:delete      => boolean`
  # `:verbose     => boolean`
  # `:archive     => boolean` (default `true`)
  # `:update      => boolean` (default `true`)
  # `:exclude     => string`
  # `:prune_empty => boolean`
  #
  # ## Examples
  #
  # Syncing a directory to a backup:
  #
  #     sync('~/music', '/backup/music')
  #
  # Excluding a path:
  #
  #     sync('~/code', '/backup/code', :exclude => '.git')
  #
  # Excluding multiple paths:
  #
  #     sync('~/code', '/backup/code', :exclude => ['.git', '.rvmrc'])
  def sync(from, to, options = {})
    # expand removes trailing slash
    # cannot use str[-1] due to ruby 1.8.7 restriction
    from = expand(from) + (from.end_with?('/') ? '/' : '')
    to = expand(to) + (to.end_with?('/') ? '/' : '')
    # default options
    options = { :archive => true, :update => true }.merge(options)
    ops = []
    ops << '-a' if options[:archive]
    ops << '-v' if options[:verbose]
    ops << '-u' if options[:update]
    ops << '-m' if options[:prune_empty]
    ops << '-n' if @file_options[:noop]

    Array(options[:exclude]).each do |path|
      ops << "--exclude=#{ path.inspect }"
    end

    ops << '--delete' if options[:delete]
    stdout = cmd("rsync #{ ops.join(' ') } #{ from.inspect } #{ to.inspect } 2>&1")
    log("Fired sync from #{ from.inspect } to #{ to.inspect }.  STDOUT:\n\n#{ stdout }")
  end

  private

  def log(message)
    @logger.info(message)
  end

  def warn(message)
    @logger.warn(message)
  end

  def expand(path)
    File.expand_path(path)
  end

  def expand_all(paths)
    Array(paths).map { |path| expand(path) }
  end
end
