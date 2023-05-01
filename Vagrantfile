# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  # See also: `script/vagrant-test`, `script/vagrant-test-all`
  config.vm.box = ENV['MAID_TARGET_BOX'] || 'ubuntu/jammy64'

  config.vm.provider :virtualbox do |vb|
    # Maid has very low system requirements
    vb.customize ['modifyvm', :id, '--cpus', 4, '--memory', 1024]
  end

  config.vm.provision(:shell, path: 'script/vagrant-provision',
                              args: ENV['MAID_TARGET_RUBY'] || File.read('.ruby-version').chomp,)
end
