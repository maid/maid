# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  # See also: `script/vagrant-test`, `script/vagrant-test-all`
  config.vm.box = ENV['MAID_TARGET_BOX'] || 'hashicorp/precise64'

  config.vm.provider :virtualbox do |vb|
    # Maid has very low system requirements
    vb.customize ['modifyvm', :id, '--cpus', 1, '--memory', 192]
  end

  config.vm.provision(:shell, path: 'script/vagrant-provision', args: ENV['MAID_TARGET_RUBY'] || '1.9.3')
end
