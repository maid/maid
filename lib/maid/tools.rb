require 'fileutils'
require 'find'
require 'time'

# Collection of utility methods included in Maid::Maid (and thus available in the rules DSL).
#
# In general, all paths are automatically expanded (e.g. '~/Downloads/foo.zip' becomes '/home/username/Downloads/foo.zip').
#
# Some methods are not available on all platforms.  An <tt>ArgumentError</tt> is raised when a command is not available.  See tags: [Mac OS X]
module Maid::Tools
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
  #   move(Dir('~/Downloads/*.zip'), '~/Archive/Software/Mac OS X/')
  def move(froms, to)
    froms = [froms] unless froms.kind_of?(Array)
    
    froms.each do |from|
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
  #   trash('~/Downloads/foo.zip')
  # 
  # This method can handle multiple paths.
  #
  #   trash(['~/Downloads/foo.zip', '~/Downloads/bar.zip'])
  #   trash(Dir('~/Downloads/*.zip'))
  def trash(paths)
    paths = [paths] unless paths.kind_of?(Array)
    
    paths.each do |path|
      target = File.join(@trash_path, File.basename(path))
      safe_trash_path = File.join(@trash_path, "#{File.basename(path)} #{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}")

      if File.exist?(target)
        move(path, safe_trash_path)
      else
        move(path, @trash_path)
      end
    end
  end

  # Give all files matching the given glob.
  #
  # Delgates to Dir.
  #
  #   dir('~/Downloads/*.zip')
  def dir(glob)
    Dir[File.expand_path(glob)]
  end

  # Find matching files, akin to the Unix utility <tt>find</tt>.
  #
  # Delegates to Find.find.
  #
  #   find '~/Downloads/' do |path|
  #     # ...
  #   end
  def find(path, &block)
    Find.find(File.expand_path(path), &block)
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
  #   disk_usage('foo.zip') # => 136
  def disk_usage(path)
    raw = cmd("du -s #{path.inspect}")
    raw.split(/\s+/).first.to_i
  end

  # In Unix speak, "atime".
  #
  #   last_accessed('foo.zip') # => Sat Apr 09 10:50:01 -0400 2011
  def last_accessed(path)
    File.atime(File.expand_path(path))
  end

  # Pulls and pushes the given git repository.
  #
  # You might also be interested in SparkleShare (http://sparkleshare.org/), a great git-based file syncronization project.
  #
  #   git_piston('~/code/projectname')
  def git_piston(path)
    full_path = File.expand_path(path)
    stdout = cmd("cd #{full_path.inspect} && git pull && git push 2>&1")
    @logger.info "Fired git piston on #{full_path.inspect}.  STDOUT:\n\n#{stdout}"
  end
end
