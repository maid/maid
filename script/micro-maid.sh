#!/usr/bin/env sh
# Script for testing Maid from scratch on MicroCore Linux (a 10 MB Linux distribution which is enough to run Maid)

if [ `whoami` == 'root' ]; then
  mkdir maid
  cd maid
  tce-fetch.sh ruby.tcz
  tce-load -i ruby.tcz
  wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.5.tgz
  tar xvfz rubygems-1.8.5.tgz
  cd rubygems-1.8.5
  ruby setup.rb
  # wget http://githubredir.debian.net/github/benjaminoakes/maid/0~master.tar.gz -O maid-master.tar.gz
  # tar xvfz maid-master.tar.gz
  gem install maid --pre
else
  echo This should be run as root.
fi
