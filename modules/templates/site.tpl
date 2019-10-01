---
- name: Install Vault
  hosts: vault_instances
  any_errors_fatal: true
  become: true
  become_user: root
  roles:
    - {role: ansible-vault}
  vars:
    ansible_ssh_user: ${ansible_user}
    vault_azurekeyvault: true
    vault_azurekeyvault_tenant_id: ${tenant_id}
    vault_azurekeyvault_vault_name: ${vault_name}
    vault_azurekeyvault_key_name: ${vault_key}
    vault_iface: eth0
    vault_install_remotely: ${vault_remote_install}
    vault_version: ${vault_version}
    vault_api_addr: https://{{inventory_hostname}}:8200
    vault_pkg: vault-enterprise_${vault_version}+ent_linux_amd64.zip
    vault_checksum_file_url: https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/vault/ent/{{vault_version}}/vault-enterprise_${vault_version}%2Bent_SHA256SUMS
    vault_zip_url: https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/vault/ent/{{vault_version}}/vault-enterprise_${vault_version}%2Bent_linux_amd64.zip
    vault_performance_standby_disable: true
    vault_ui: true
    vault_tls_disable: true
    vault_awskms: false

- name: Preparing Ansible TOwer hosts
  hosts: tower_instances
  any_errors_fatal: true
  become: true
  become_user: root
  roles :
    - {role: tower-preps}
  
    
