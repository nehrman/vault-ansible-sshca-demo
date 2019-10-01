output "resource_group_id" {
  description = "id of resource group"
  value       = "${module.vaultprimarycluster.resource_group_id}"
}

output "resource_group_name" {
  description = "name of resource group"
  value       = "${module.vaultprimarycluster.resource_group_name}"
}

output "virtual_network_name" {
  description = "name of virtual network created in resource group"
  value       = "${module.vaultprimarycluster.virtual_network_name}"
}

output "virtual_network_id" {
  description = "id of virtual network created in resource group"
  value       = "${module.vaultprimarycluster.virtual_network_id}"
}

output "virtual_network_subnets_name" {
  description = "name of subnets created inside the new vNet"
  value       = "${module.vaultprimarycluster.virtual_network_subnets_name}"
}

output "virtual_network_subnets_id" {
  description = "The ids of subnets created inside the new vNet"
  value       = "${module.vaultprimarycluster.virtual_network_subnets_id}"
}

output "load_balancer_id" {
  description = "the id for the azurerm_lb resource"
  value       = "${module.vaultprimarycluster.load_balancer_id}"
}

output "load_balancer_backend_pool_id" {
  description = "the id for the azurerm_lb_backend_address_pool resource"
  value       = "$${module.vaultprimarycluster.load_balancer_backend_pool_id}"
}

output "load_balancer_public_ip_address" {
  description = "the ip address for the azurerm_lb_public_ip resource"
  value       = "${module.vaultprimarycluster.load_balancer_public_ip_address}"
}

output "bastion_virtual_machine_name" {
  description = "name of virtual machines"
  value       = "${module.vaultprimarycluster.bastion_virtual_machine_name}"
}

output "bastion_network_interface_name" {
  description = "name of network interface attached to vm"
  value       = "${module.vaultprimarycluster.bastion_network_interface_name}"
}

output "bastion_network_interface_private_ip" {
  description = "private ip addresses of the vm nics"
  value       = "${module.vaultprimarycluster.bastion_network_interface_private_ip}"
}

output "bastion_network_interface_public_ip" {
  description = "private ip addresses of the vm nics"
  value       = "${module.vaultprimarycluster.bastion_network_interface_public_ip}"
}
