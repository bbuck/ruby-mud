# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  config.vm.box = "leopard/rwtrusty64"

  config.vm.network :forwarded_port, guest: 8080, host: 8081

  config.vm.provision :shell, path: "bootstrap.sh"
end
