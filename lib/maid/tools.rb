require 'digest/sha1'
require 'find'
require 'fileutils'
require 'time'

require 'exifr/jpeg'
require 'geocoder'
require 'mime/types'
require 'dimensions'
require 'zip'

require 'pathname'

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
  # For showing deprecation notices
  include Deprecated

  # Move `sources` to a `destination` directory.
  #
  # Movement is only allowed to directories that already exist.  If your intention is to rename, see the `rename` method.
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
    expanded_destination = expand(destination)

    if File.directory?(expanded_destination)
      expand_all(sources).each do |source|
        log("move #{ sh_escape(source) } #{ sh_escape(expanded_destination) }")
        FileUtils.mv(source, expanded_destination, @file_options)
      end
    else
      # Unix `mv` warns about the target not being a directory with multiple sources.  Maid checks the same.
      warn("skipping move because #{ sh_escape(expanded_destination) } is not a directory (use 'mkdir' to create first, or use 'rename')")
    end
  end

  # Rename a single file.
  #
  # Any directories needed in order to complete the rename are made automatically.
  #
  # Overwriting is not allowed; it logs a warning.  If overwriting is desired, use `remove` to delete the file first, then use `rename`.
  #
  # ## Examples
  #
  # Simple rename:
  #
  #     rename('foo.zip', 'baz.zip') # "foo.zip" becomes "baz.zip"
  #
  # Rename needing directories:
  #
  #     rename('foo.zip', 'bar/baz.zip') # "bar" is created, "foo.zip" becomes "baz.zip" within "bar"
  #
  # Attempting to overwrite:
  #
  #     rename('foo.zip', 'existing.zip') # "skipping move of..."
  def rename(source, destination)
    source = expand(source)
    destination = expand(destination)

    mkdir(File.dirname(destination))

    if File.exist?(destination)
      warn("skipping rename of #{ sh_escape(source) } to #{ sh_escape(destination) } because it would overwrite")
    else
      log("rename #{ sh_escape(source) } #{ sh_escape(destination) }")
      FileUtils.mv(source, destination, @file_options)
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
          rename(path, safe_trash_path)
        else
          move(path, @trash_path)
        end
      end
    end
  end

  # Copy from `sources` to `destination`
  #
  # The path is not copied if a file already exists at the destination with the same name.  A warning is logged instead.
  # Note: Similar functionality is provided by the sync tool, but this requires installation of the `rsync` binary
  # ## Examples
  #
  # Single path:
  #
  #     copy('~/Downloads/foo.zip', '~/Archive/Software/Mac OS X/')
  #
  # Multiple paths:
  #
  #     copy(['~/Downloads/foo.zip', '~/Downloads/bar.zip'], '~/Archive/Software/Mac OS X/')
  #     copy(dir('~/Downloads/*.zip'), '~/Archive/Software/Mac OS X/')
  def copy(sources, destination)
    destination = expand(destination)

    expand_all(sources).each do |source|
        target = File.join(destination, File.basename(source))

      unless File.exist?(target)
        log("cp #{ sh_escape(source) } #{ sh_escape(destination) }")
        FileUtils.cp(source, destination, @file_options)
      else
        warn("skipping copy because #{ sh_escape(source) } because #{ sh_escape(target) } already exists")
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

      log("Removing #{ sh_escape(path) }")
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
  # Multiple glob (all are equivalent):
  #
  #     dir(['~/Downloads/*.zip', '~/Dropbox/*.zip'])
  #     dir(%w(~/Downloads/*.zip ~/Dropbox/*.zip))
  #     dir('~/{Downloads,Dropbox}/*.zip')
  #
  # Recursing into subdirectories (see also: `find`):
  #
  #     dir('~/Music/**/*.m4a')
  #
  def dir(globs)
    expand_all(globs).
      map { |glob| Dir.glob(glob) }.
      flatten.
      sort
  end

  # Same as `dir`, but excludes files that are (possibly) being
  # downloaded.
  #
  # ## Example
  #
  # Move Debian/Ubuntu packages that are finished downloading into a software directory.
  #
  #     move dir_safe('~/Downloads/*.deb'), '~/Archive/Software'
  #
  def dir_safe(globs)
    dir(globs).
      reject { |path| downloading?(path) }
  end

  # Give only files matching the given glob.
  #
  # This is the same as `dir` but only includes actual files (no directories or symlinks).
  #
  def files(globs)
    dir(globs).
      select { |f| File.file?(f) }
  end

  # Escape characters that have special meaning as a part of path global patterns.
  #
  # Useful when using `dir` with file names that may contain `{ } [ ]` characters.
  #
  # ## Example
  #
  #     escape_glob('test [tmp]') # => 'test \\[tmp\\]'
  def escape_glob(glob)
    glob.gsub(/[\{\}\[\]]/) { |s| '\\' + s }
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
    log("mkdir -p #{ sh_escape(path) }")
    FileUtils.mkdir_p(path, @file_options.merge(options))
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
  # Recursing and filtering using a regular expression:
  #
  #     find('~/Downloads/').grep(/\.pdf$/)
  #
  # (**Note:** It's just Ruby, so any methods in `Array` and `Enumerable` can be used.)
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
      Find.find(expanded_path).to_a
    else
      Find.find(expanded_path, &block)
    end
  end

  # [Mac OS X] Use Spotlight to locate all files matching the given filename.
  #
  # [Ubuntu] Use `locate` to locate all files matching the given filename.
  #
  # ## Examples
  #
  #     locate('foo.zip') # => ['/a/foo.zip', '/b/foo.zip']
  def locate(name)
    cmd("#{Maid::Platform::Commands.locate} #{ sh_escape(name) }").split("\n")
  end

  # [Mac OS X] Use Spotlight metadata to determine the site from which a file was downloaded.
  #
  # ## Examples
  #
  #     downloaded_from('foo.zip') # => ['http://www.site.com/foo.zip', 'http://www.site.com/']
  def downloaded_from(path)
    mdls_to_array(path, 'kMDItemWhereFroms')
  end

  # Detect whether the path is currently being downloaded in Chrome, Firefox or Safari.
  #
  # See also: `dir_safe`
  def downloading?(path)
    Maid::Downloading.downloading?(path)
  end

  # Find all duplicate files in the given globs.
  #
  # More often than not, you'll want to use `newest_dupes_in` or
  # `verbose_dupes_in` instead of using this method directly.
  #
  # Globs are expanded as in `dir`, then all non-files are filtered out. The
  # remaining files are compared by size, and non-dupes are filtered out. The
  # remaining candidates are then compared by checksum. Dupes are returned as
  # an array of arrays.
  #
  # ## Examples
  #
  #     dupes_in('~/{Downloads,Desktop}/*') # => [
  #                                                ['~/Downloads/foo.zip', '~/Downloads/foo (1).zip'],
  #                                                ['~/Desktop/bar.txt', '~/Desktop/bar copy.txt']
  #                                              ]
  #
  # Keep the newest dupe:
  #
  #     dupes_in('~/Desktop/*', '~/Downloads/*').each do |dupes|
  #       trash dupes.sort_by { |p| File.mtime(p) }[0..-2]
  #     end
  #
  def dupes_in(globs)
    dupes = []
    files(globs).                           # Start by filtering out non-files
      group_by { |f| size_of(f) }.          # ... then grouping by size, since that's fast
      reject { |s, p| p.length < 2 }.       # ... and filter out any non-dupes
      map do |size, candidates|
        dupes += candidates.
          group_by { |p| checksum_of(p) }.  # Now group our candidates by a slower checksum calculation
          reject { |c, p| p.length < 2 }.   # ... and filter out any non-dupes
          values
      end
    dupes
  end

  # Convenience method that is like `dupes_in` but excludes the oldest dupe.
  #
  # ## Example
  #
  # Keep the oldest dupe (trash the others):
  #
  #     trash newest_dupes_in('~/Downloads/*')
  #
  def newest_dupes_in(globs)
    dupes_in(globs).
      map { |dupes| dupes.sort_by { |p| File.mtime(p) }[1..-1] }.
      flatten
  end

  # Convenience method for `dupes_in` that excludes the dupe with the shortest name.
  #
  # This is ideal for dupes like `foo.zip`, `foo (1).zip`, `foo copy.zip`.
  #
  # ## Example
  #
  # Keep the dupe with the shortest name (trash the others):
  #
  #     trash verbose_dupes_in('~/Downloads/*')
  #
  def verbose_dupes_in(globs)
    dupes_in(globs).
      map { |dupes| dupes.sort_by { |p| File.basename(p).length }[1..-1] }.
      flatten
  end

  # Determine the dimensions of GIF, PNG, JPEG, or TIFF images.
  #
  # Value returned is [width, height].
  #
  # ## Examples
  #
  #     dimensions_px('image.jpg') # => [1024, 768]
  #     width, height = dimensions_px('image.jpg')
  #     dimensions_px('image.jpg').join('x') # => "1024x768"
  def dimensions_px(path)
    Dimensions.dimensions(path)
  end

  # Determine the city of the given JPEG image.
  #
  # ## Examples
  #
  #     loation_city('old_capitol.jpg') # => "Iowa City, IA, US"
  def location_city(path)
    case mime_type(path)
    when 'image/jpeg'
      gps = EXIFR::JPEG.new(path).gps
      coordinates_string = [gps.latitude, gps.longitude]
      location = Geocoder.search(coordinates_string).first
      [location.city, location.province, location.country_code.upcase].join(', ')
    end
  end

  # [Mac OS X] Use Spotlight metadata to determine audio length.
  #
  # ## Examples
  #
  #     duration_s('foo.mp3') # => 235.705
  def duration_s(path)
    cmd("mdls -raw -name kMDItemDurationSeconds #{ sh_escape(path) }").to_f
  end

  # List the contents of a zip file.
  #
  # ## Examples
  #
  #     zipfile_contents('foo.zip') # => ['foo.exe', 'README.txt', 'subdir/anything.txt']
  def zipfile_contents(path)
    # It might be nice to use `glob` from `Zip::FileSystem`, but it seems buggy.  (Subdirectories aren't included.)
    Zip::File.open(path) do |zip_file|
      zip_file.entries.map { |entry| entry.name }.sort
    end
  end

  # Calculate disk usage of a given path in kilobytes.
  #
  # See also: `Maid::NumericExtensions::SizeToKb`.
  #
  # ## Examples
  #
  #     disk_usage('foo.zip') # => 136
  def disk_usage(path)
    raw = cmd("du -s #{ sh_escape(path) }")
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

  # Get the size of a file.
  #
  # ## Examples
  #
  #     size_of('foo.zip') # => 2193
  def size_of(path)
    File.size(path)
  end

  # Get a checksum for a file.
  #
  # ## Examples
  #
  #     checksum_of('foo.zip') # => "67258d750ca654d5d3c7b06bd2a1c792ced2003e"
  def checksum_of(path)
    Digest::SHA1.hexdigest(File.read(path))
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
    stdout = cmd("cd #{ sh_escape(full_path) } && git pull && git push 2>&1")
    log("Fired git piston on #{ sh_escape(full_path) }.  STDOUT:\n\n#{ stdout }")
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
      ops << "--exclude=#{ sh_escape(path) }"
    end

    ops << '--delete' if options[:delete]
    stdout = cmd("rsync #{ ops.join(' ') } #{ sh_escape(from) } #{ sh_escape(to) } 2>&1")
    log("Fired sync from #{ sh_escape(from) } to #{ sh_escape(to) }.  STDOUT:\n\n#{ stdout }")
  end

  # [Mac OS X] Use Spotlight metadata to determine which content types a file has.
  #
  # ## Examples
  #
  #     spotlight_content_types('foo.zip') # => ['public.zip-archive', 'public.archive']
  def spotlight_content_types(path)
    mdls_to_array(path, 'kMDItemContentTypeTree')
  end

  # Get the content types of a path.
  #
  # Content types can be MIME types, Internet media types or Spotlight content types (OS X only).
  #
  # ## Examples
  #
  #     content_types('foo.zip') # => ["public.zip-archive", "com.pkware.zip-archive", "public.archive", "application/zip", "application"]
  #     content_types('bar.jpg') # => ["public.jpeg", "public.image", "image/jpeg", "image"]
  def content_types(path)
    [spotlight_content_types(path), mime_type(path), media_type(path)].flatten
  end

  # Get the MIME type of the file.
  #
  # ## Examples
  #
  #     mime_type('bar.jpg') # => "image/jpeg"
  def mime_type(path)
    type = MIME::Types.type_for(path)[0]

    if type
      [type.media_type, type.sub_type].join('/')
    end
  end

  # Get the Internet media type of the file.
  #
  # In other words, the first part of `mime_type`.
  #
  # ## Examples
  #
  #     media_type('bar.jpg') # => "image"
  def media_type(path)
    type = MIME::Types.type_for(path)[0]

    if type
      type.media_type
    end
  end

  # Filter an array by content types.
  #
  # Content types can be MIME types, internet media types or Spotlight content types (OS X only).
  #
  # If you need your rules to work on multiple platforms, it's recommended to avoid using Spotlight content types.
  #
  # ## Examples
  #
  # ### Using media types
  #
  #     where_content_type(dir('~/Downloads/*'), 'video')
  #     where_content_type(dir('~/Downloads/*'), ['image', 'audio'])
  #
  # ### Using MIME types
  #
  #     where_content_type(dir('~/Downloads/*'), 'image/jpeg')
  #
  # ### Using Spotlight content types
  #
  # Less portable, but richer data in some cases.
  #
  #     where_content_type(dir('~/Downloads/*'), 'public.image')
  def where_content_type(paths, filter_types)
    filter_types = Array(filter_types)
    Array(paths).select { |p| !(filter_types & content_types(p)).empty? }
  end

  # Test whether a directory is either empty, or contains only empty
  # directories/subdirectories.
  #
  # ## Example
  #
  #     if tree_empty?(dir('~/Downloads/foo'))
  #       trash('~/Downloads/foo')
  #     end
  def tree_empty?(root)
    return nil if File.file?(root)
    return true if Dir.glob(root + '/*').length == 0

    ignore = []

    # Look for files.
    return false if Dir.glob(root + '/*').select { |f| File.file?(f) }.length > 0

    empty_dirs = Dir.glob(root + '/**/*').select { |d|
      File.directory?(d)
    }.reverse.select { |d|
      # `.reverse` sorts deeper directories first.

      # If the directory is empty, its parent should ignore it.
      should_ignore = Dir.glob(d + '/*').select { |n|
        !ignore.include?(n)
      }.length == 0

      ignore << d if should_ignore

      should_ignore
    }

    Dir.glob(root + '/*').select { |n|
      !empty_dirs.include?(n)
    }.length == 0
  end

  # Given an array of directories, return a new array without any child
  # directories whose parent is already present in that array.
  #
  # ## Example
  #
  #     ignore_child_dirs(["foo", "foo/a", "foo/b", "bar"]) # => ["foo", "bar"]
  def ignore_child_dirs(arr)
    arr.sort { |x, y|
      y.count('/') - x.count('/')
    }.select { |d|
      !arr.include?(File.dirname(d))
    }
  end


  # Get a list of Finder labels of a file or directory. Only available on OS X when you have tag installed.
  #
  # ## Example
  #
  #     tags("~/Downloads/a.dmg.download") # => ["Unfinished"]
  def tags(path)
    if has_tag_available_and_warn?
      path = expand(path)
      raw = cmd("tag -lN #{sh_escape(path)}")
      raw.strip.split(',')
    else
      []
    end
  end

  # Tell if a file or directory has any Finder labels. Only available on OS X when you have tag installed.
  #
  # ## Example
  #
  #     has_tags?("~/Downloads/a.dmg.download") # => true
  def has_tags?(path)
    if has_tag_available_and_warn?
      ts = tags(path)
      ts && ts.count > 0
    else
      false
    end
  end

  # Tell if a file or directory has a certain Finder labels. Only available on OS X when you have tag installed.
  #
  # ## Example
  #
  #     contains_tag?("~/Downloads/a.dmg.download", "Unfinished") # => true
  def contains_tag?(path, tag)
    if has_tag_available_and_warn?
      path = expand(path)
      ts = tags(path)
      ts.include?(tag)
    else
      false
    end
  end

  # Add a Finder label or a list of labels to a file or directory. Only available on OS X when you have tag installed.
  #
  # ## Example
  #
  #     add_tag("~/Downloads/a.dmg.download", "Unfinished")
  def add_tag(path, tag)
    if has_tag_available_and_warn?
      path = expand(path)
      ts = Array(tag).join(",")
      log "add tags #{ts} to #{path}"
      if !@file_options[:noop]
        cmd("tag -a #{sh_escape(ts)} #{sh_escape(path)}")
      end
    end
  end

  # Remove a Finder label or a list of labels from a file or directory. Only available on OS X when you have tag installed.
  #
  # ## Example
  #
  #     remove_tag("~/Downloads/a.dmg", "Unfinished")
  def remove_tag(path, tag)
    if has_tag_available_and_warn?
      path = expand(path)
      ts = Array(tag).join(",")
      log "remove tags #{ts} from #{path}"
      if !@file_options[:noop]
        cmd("tag -r #{sh_escape(ts)} #{sh_escape(path)}")
      end
    end
  end

  # Set Finder label of a file or directory to a label or a list of labels. Only available on OS X when you have tag installed.
  #
  # ## Example
  #
  #     set_tag("~/Downloads/a.dmg.download", "Unfinished")
  def set_tag(path, tag)
    if has_tag_available_and_warn?
      path = expand(path)
      ts = Array(tag).join(",")
      log "set tags #{ts} to #{path}"
      if !@file_options[:noop]
        cmd("tag -s #{sh_escape(ts)} #{sh_escape(path)}")
      end
    end
  end

  # Tell if a file is hidden
  #
  # ## Example
  #
  #     hidden?("~/.maid") # => true
  def hidden?(path)
    if Maid::Platform.osx?
      raw = cmd("mdls -raw -name kMDItemFSInvisible #{ sh_escape(path) }")
      raw == '1'
    else
      p = Pathname.new(expand(path))
      p.basename =~ /^\./
    end
  end

  # Tell if a file has been used since added
  #
  # ## Example
  #
  #     has_been_used?("~/Downloads/downloading.download") # => false
  def has_been_used?(path)
    if Maid::Platform.osx?
      path = expand(path)
      raw = cmd("mdls -raw -name kMDItemLastUsedDate #{ sh_escape(path) }")

      if raw == "(null)"
        false
      else
        begin
          DateTime.parse(raw).to_time
          true
        rescue ArgumentError => e
          false
        end
      end
    else
      used_at(path) <=> added_at(path) > 0
    end
  end

  # The last used time of a file on OS X, or atime on Linux.
  #
  # ## Example
  #
  #     used_at("foo.zip") # => Sat Apr 09 10:50:01 -0400 2011
  def used_at(path)
    if Maid::Platform.osx?
      path = expand(path)
      raw = cmd("mdls -raw -name kMDItemLastUsedDate #{ sh_escape(path) }")

      if raw == "(null)"
        nil
      else
        begin
          DateTime.parse(raw).to_time
        rescue ArgumentError => e
          accessed_at(path)
        end
      end
    else
      accessed_at(path)
    end
  end

  # The added time of a file on OS X, or ctime on Linux.
  #
  # ## Example
  #
  #     added_at("foo.zip") # => Sat Apr 09 10:50:01 -0400 2011
  def added_at(path)
    if Maid::Platform.osx?
      path = expand(path)
      raw = cmd("mdls -raw -name kMDItemDateAdded #{ sh_escape(path) }")

      if raw == "(null)"
        1.second.ago
      else
        begin
          DateTime.parse(raw).to_time
        rescue ArgumentError => e
          created_at(path)
        end
      end
    else
      created_at(path)
    end
  end

  private

  def has_tag_available?
    Maid::Platform.has_tag_available?
  end

  def has_tag_available_and_warn?
    if has_tag_available?
      true
    else
      if Maid::Platform.osx?
        warn("To use this feature, you need `tag` installed.  Run `brew install tag`")
      else
        warn("sorry, tagging is unavailable on your platform")
      end

      false
    end
  end

  def sh_escape(array)
    Escape.shell_command(Array(array))
  end

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

  def mdls_to_array(path, attribute)
    if Maid::Platform.osx?
      raw = cmd("mdls -raw -name #{sh_escape(attribute)} #{ sh_escape(path) }")

      if raw.empty?
        []
      else
        clean = raw[1, raw.length - 2]
        clean.split(/,\s+/).map { |s| t = s.strip; t[1, t.length - 2] }
      end
    else
      []
    end
  end
end
