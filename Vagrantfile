# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # The base precise64 box can be found at http://files.vagrantup.com/precise64.box
  # 
  # For more info, please see https://github.com/benjaminoakes/maid/wiki/Contributing
  config.vm.box = 'precise64'

  config.vm.provision(:shell, :path => 'script/provision')
end
