# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # See also: `script/vagrant-test`, `script/vagrant-test-all`
  config.vm.box = ENV['MAID_TARGET_BOX'] || 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box' if 'precise64' == config.vm.box

  config.vm.provision(:shell, :path => 'script/vagrant-provision', :args => ENV['MAID_TARGET_RUBY'] || '1.9.3')
end
