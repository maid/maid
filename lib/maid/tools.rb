require 'fileutils'
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
end
