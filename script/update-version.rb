#!/usr/bin/env ruby
# shellcheck disable=SC1071
# Shellcheck doesn't do ruby
version = ARGV[0]
version_file = 'lib/maid/version.rb'
gemfile_lock = 'Gemfile.lock'

content_version = File.read(version_file)
updated_version = content_version.gsub(/VERSION *= *['"].*?['"]/, "VERSION = '#{version}'")
File.write(version_file, updated_version)

content_gemfile = File.read(gemfile_lock)
updated_gemfile = content_gemfile.gsub(/    maid (.*)/, "    maid (#{version})")
File.write(gemfile_lock, updated_gemfile)
