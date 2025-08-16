#!/usr/bin/env ruby
version = ARGV[0]
version_file = 'lib/maid/version.rb'

content = File.read(version_file)
updated = content.gsub(/VERSION\s*=\s*['"].*?['"]/, "VERSION =
'#{version}'",)
File.write(version_file, updated)
