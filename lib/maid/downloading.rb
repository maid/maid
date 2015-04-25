module Maid::Downloading
  class << self
    def downloading?(path)
      !!(downloading_file_regexps.any? { |re| path.match(re) } || firefox_extra?(path) || aria2_extra?(path))
    end

    def downloading_file_regexps
      [/\.crdownload$/, /\.download$/, /\.aria2$/, /\.td$/, /\.td.cfg$/, /\.part$/]
    end

    def firefox_extra?(path)
      File.exist?("#{path}.part")
    end

    def aria2_extra?(path)
      File.exist?("#{path}.aria2")
    end
  end
end
