# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # ## Base Boxes
  #
  # To add a [box](http://vagrantup.com/v1/docs/boxes.html):
  #
  #     vagrant box add $box_name $box_url
  #
  # Base boxes for supported releases are listed below.  The idea is to come close to the [official Canonical support timeline](http://en.wikipedia.org/wiki/Ubuntu_releases#Table_of_versions), when possible.
  #
  # ### Releases preferred with Ruby 1.8.7
  #
  # These older releases of Ubuntu don't provide a prebuilt package for Ruby 1.9.3.
  #
  # Supported until 2015-04:
  #
  # * `lucid32`: http://files.vagrantup.com/lucid32.box
  # * `lucid64`: http://files.vagrantup.com/lucid64.box
  #
  # ### Releases preferred with Ruby 1.9.3
  #
  # Supported until 2017-04:
  #
  # * `precise32`: http://files.vagrantup.com/precise32.box
  # * `precise64`: http://files.vagrantup.com/precise64.box
  #
  # Supported until 2014-04:
  #
  # * `quantal64`: https://github.com/downloads/roderik/VagrantQuantal64Box/quantal64.box
  #
  # ## See Also
  # 
  # * [Vagrant Boxes List](http://www.vagrantbox.es/)
  # * [Contributing Guide](https://github.com/benjaminoakes/maid/wiki/Contributing)
  config.vm.box = 'precise64'

  config.vm.provision(:shell, :path => 'script/vagrant-provision')
end
