require 'fileutils'

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
end
