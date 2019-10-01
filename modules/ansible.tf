##
## here we create the list of available Consul Client nodes
## to be used as input for the ansible_groups template
##

data "template_file" "ansible_tower_server_hosts" {
  count      = "${var.az_tower_nb_instance}"
  template   = "${file("${path.module}/templates/ansible_tower_server_hosts.tpl")}"
  depends_on = ["azurerm_virtual_machine.tower", "azurerm_virtual_machine.vault"]

  vars {
    consul_node_server_name = "${element(azurerm_virtual_machine.consul.*.name, count.index)}"
    consul_server_role      = "${element(azurerm_virtual_machine.consul.*.name, count.index) == element(azurerm_virtual_machine.consul.*.name, 0) ? var.consul_role_bootstrap : var.consul_role_server}"
    consul_bind_address     = "${element(azurerm_network_interface.consul.*.private_ip_address, count.index)}"
  }
}

##
## here we create the list of available Vault nodes
## to be used as input for the ansible_groups template
##
data "template_file" "ansible_vault_hosts" {
  count      = "${var.az_vault_nb_instance}"
  template   = "${file("${path.module}/templates/ansible_vault_hosts.tpl")}"
  depends_on = ["azurerm_virtual_machine.vault"]

  vars {
    vault_node_name = "${element(azurerm_virtual_machine.vault.*.name, count.index)}"
  }
}

##
## here we assign Consul and Vault Nodes to the right GROUP
## 
data "template_file" "ansible_groups" {
  template = "${file("${path.module}/templates/ansible_groups.tpl")}"

  vars {
    tower_server_hosts_def = "${join("",data.template_file.ansible_tower_server_hosts.*.rendered)}"
    vault_hosts_def         = "${join("",data.template_file.ansible_vault_hosts.*.rendered)}"
  }
}

##
## here we write the rendered "ansible_groups" template into a local file
## on the Terraform exec environment (the shell where the terraform binary runs)
##
resource "local_file" "ansible_inventory" {
  depends_on = ["data.template_file.ansible_groups"]

  content  = "${data.template_file.ansible_groups.rendered}"
  filename = "${path.module}/ansible/hosts"
}

##
## here we create the Ansible Configuration 
## to be used by Ansible 
##
data "template_file" "ansible_cfg" {
  template   = "${file("${path.module}/templates/ansible_cfg.tpl")}"
  depends_on = ["azurerm_virtual_machine.vault"]

  vars {
    ansible_user = "${var.global_admin_username}"
  }
}

##
## here we write the rendered ansible configuration
## on the Terraform exec environment (the shell where the terraform binary runs)
##
resource "local_file" "ansible_cfg" {
  depends_on = ["data.template_file.ansible_cfg"]

  content  = "${data.template_file.ansible_cfg.rendered}"
  filename = "${path.module}/ansible/.ansible.cfg"
}

##
## here we create the customize the Ansible playbook
## to be used as input for Ansible deployment
##
data "template_file" "ansible_site" {
  #  count      = "${var.az_consul_nb_instance}"
  template   = "${file("${path.module}/templates/site.tpl")}"
  depends_on = ["azurerm_virtual_machine.consul", "azurerm_virtual_machine.vault"]

  vars {
    ansible_user          = "${var.global_admin_username}"
    consul_version        = "${var.consul_version}"
    consul_remote_install = "${var.consul_remote_install}"
    vault_version         = "${var.vault_version}"
    vault_remote_install  = "${var.vault_remote_install}"
    vault_name            = "${azurerm_key_vault.vault_unseal.name}"
    vault_key             = "${azurerm_key_vault_key.vault_unseal.name}"
    tenant_id             = "${data.azurerm_client_config.current.tenant_id}"
  }
}

##
## here we write the rendered "site" playbook template into a local file
## on the Terraform exec environment (the shell where the terraform binary runs)
##
resource "local_file" "ansible_playbook" {
  depends_on = ["data.template_file.ansible_site"]

  content  = "${data.template_file.ansible_site.rendered}"
  filename = "${path.module}/ansible/site.yml"
}

##
## here we copy the local file to the bastion
## using a "null_resource" to be able to trigger a file provisioner
##
resource "null_resource" "ansible_copy" {
  depends_on = ["local_file.ansible_inventory", "local_file.ansible_playbook"]

  triggers {
    always_run = "${timestamp()}"
  }

  provisioner "file" {
    source      = "${path.module}/ansible/"
    destination = "~/"

    connection {
      type        = "ssh"
      host        = "${azurerm_public_ip.bastion.ip_address}"
      user        = "${var.global_admin_username}"
      private_key = "${file(var.id_rsa_path)}"
      insecure    = true
    }
  }
}

##
## here we copy the local file to the bastion
## using a "null_resource" to be able to trigger a file provisioner
##
resource "null_resource" "ansible_ssh_id" {
  provisioner "file" {
    content     = "${file(var.id_rsa_path)}"
    destination = "~/.ssh/id_rsa"

    connection {
      type        = "ssh"
      host        = "${azurerm_public_ip.bastion.ip_address}"
      user        = "${var.global_admin_username}"
      private_key = "${file(var.id_rsa_path)}"
      insecure    = true
    }
  }
}

resource "null_resource" "ansible_run" {
  depends_on = ["null_resource.ansible_ssh_id", "null_resource.ansible_copy", "local_file.ansible_inventory", "azurerm_virtual_machine.bastion", "azurerm_virtual_machine.vault", "azurerm_virtual_machine.consul", "azurerm_virtual_machine_extension.bastion"]

  triggers {
    always_run = "${timestamp()}"
  }

  connection {
    type        = "ssh"
    host        = "${azurerm_public_ip.bastion.ip_address}"
    user        = "${var.global_admin_username}"
    private_key = "${file(var.id_rsa_path)}"
    insecure    = true
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0600 ~/.ssh/id_rsa",
      "git clone https://github.com/nehrman/ansible-vault ~/roles/ansible-vault",
      "git clone https://github.com/nehrman/ansible-consul ~/roles/ansible-consul",
      "sleep 30 && ansible-playbook -i ~/hosts ~/site.yml ",
    ]
  }
}
