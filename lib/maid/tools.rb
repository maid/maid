require 'fileutils'
require 'find'
require 'time'

module Maid::Tools
  def move(from, to)
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
 
  def trash(path)
    target = File.join(@trash_path, File.basename(path))
    safe_trash_path = File.join(@trash_path, "#{File.basename(path)} #{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}")
  
    if File.exist?(target)
      move(path, safe_trash_path)
    else
      move(path, @trash_path)
    end
  end

  def dir(glob)
    Dir[File.expand_path(glob)]
  end

  def find(path, &block)
    Find.find(File.expand_path(path), &block)
  end

  # Made primarily for testability.  Delegates to Kernel.`
  def cmd(command)
    %x(#{command})
  end

  def downloaded_from(path)
    raw = cmd("mdls -raw -name kMDItemWhereFroms #{path.inspect}")
    clean = raw[1, raw.length - 2]
    clean.split(/,\s+/).map { |s| t = s.strip; t[1, t.length - 2] }
  end

  def duration_s(path)
    cmd("mdls -raw -name kMDItemDurationSeconds #{path.inspect}").to_f
  end

  def locate(name)
    cmd("mdfind -name #{name.inspect}").split("\n")
  end

  def zipfile_contents(path)
    raw = cmd("unzip -Z1 #{path.inspect}")
    raw.split("\n")
  end

  def disk_usage(path)
    raw = cmd("du -s #{path.inspect}")
    raw.split(/\s+/).first.to_i
  end

  def git_piston(path)
    full_path = File.expand_path(path)
    stdout = cmd("cd #{full_path.inspect} && git pull && git push 2>&1")
    @logger.info "Fired piston on #{full_path.inspect}.  STDOUT:\n\n#{stdout}"
  end
end
