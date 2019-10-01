# Create Public IP Address for the Bastion
resource "azurerm_public_ip" "bastion" {
  count               = "${var.az_bastion_nb_instance}"
  name                = "${var.az_env}-${var.az_prefix}-bastion-pubip"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.az_location}"
  allocation_method   = "${var.az_pubip_address_alloc}"
  domain_name_label   = "${var.az_env}-${var.az_prefix}-bastion-${count.index}"
  tags                = "${var.az_tags}"
}

# Create Network Nic to use with VM
resource "azurerm_network_interface" "bastion" {
  count                     = "${var.az_bastion_nb_instance}"
  name                      = "${var.az_env}-${var.az_prefix}-bastion-nic-${count.index}"
  location                  = "${var.az_location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.bastion-nsg.id}"

  ip_configuration {
    name                          = "ipconf${count.index}"
    subnet_id                     = "${element(azurerm_subnet.subnet.*.id, 0)}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bastion.id}"
  }

  tags = "${var.az_tags}"
}

# Create Azure Bastion Server Instances
resource "azurerm_virtual_machine" "bastion" {
  count                 = "${var.az_bastion_nb_instance}"
  name                  = "${var.az_env}-${var.az_prefix}-bastion-${count.index}"
  location              = "${var.az_location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.bastion.*.id, count.index)}"]
  vm_size               = "${var.az_instance_type}"
  availability_set_id   = "${azurerm_availability_set.avset.id}"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.az_env}-${var.az_prefix}-bastion-${count.index}-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.az_env}-${var.az_prefix}-bastion-${count.index}"
    admin_username = "${var.global_admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.global_admin_username}/.ssh/authorized_keys"
      key_data = "${element(var.ssh_public_key, 0)}"
    }
  }

  tags = "${var.az_tags}"

  lifecycle {
    create_before_destroy = true
  }
}

# Create an Azure Virtual Machine Extension taht ensure Ansible and Python-PIP are installed on the VM.

resource "azurerm_virtual_machine_extension" "bastion" {
  count                = "${var.az_bastion_nb_instance}"
  name                 = "bastion"
  location             = "${var.az_location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_machine_name = "${var.az_env}-${var.az_prefix}-bastion-${count.index}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = ["azurerm_virtual_machine.bastion"]

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get install -y ansible python-pip"
    }
SETTINGS

  tags = "${var.az_tags}"
}
