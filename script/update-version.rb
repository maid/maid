#!/usr/bin/env ruby
# shellcheck disable=SC1071
version = ARGV[0]
version_file = 'lib/maid/version.rb'

content = File.read(version_file)
updated = content.gsub(/VERSION\s*=\s*['"].*?['"]/, "VERSION = '#{version}'",)
File.write(version_file, updated)
