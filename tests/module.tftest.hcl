mock_provider "azurerm" {}
mock_provider "popsrox" {}

variables {
  location                     = "eastus"
  environment                  = "public"
  existing_resource_group_name = "rg-test"
  virtual_network_name         = "vnet-test"
  workload_name                = "workload"
  org_name                     = "org"
  deploy_environment           = "dev"
}

override_module {
  target = module.mod_azure_region_lookup
  outputs = {
    location_cli   = "eastus"
    location_short = "eus"
  }
}

override_data {
  target = data.azurerm_resource_group.rgrp[0]
  values = {
    name     = "rg-test"
    location = "eastus"
  }
}

override_data {
  target = data.azurerm_resource_group.rg
  values = {
    name     = "rg-test"
    location = "eastus"
  }
}

override_data {
  target = data.azurerm_virtual_network.vnet
  values = {
    name = "vnet-test"
  }
}

override_data {
  target = data.popsrox_resource_name.bastion
  values = {
    result = "generated-bastion"
  }
}

override_data {
  target = data.popsrox_resource_name.bastion_pip
  values = {
    result = "generated-pip"
  }
}

override_data {
  target = data.popsrox_resource_name.bastion_snet
  values = {
    result = "generated-snet"
  }
}

run "custom_names_tags_location_and_locks_enabled" {
  command = plan

  variables {
    custom_bastion_name   = "custom-bas"
    custom_public_ip_name = "custom-pip"
    custom_ipconfig_name  = "custom-ipconfig"
    domain_name_label     = "explicit-dns"
    bastion_sku           = "Standard"
    enable_copy_paste     = false
    enable_file_copy      = true
    enable_ip_connect     = true
    enable_shareable_link = true
    enable_tunneling      = true
    enable_resource_locks = true
    add_tags = {
      environment = "override"
      owner       = "platform"
    }
  }

  assert {
    condition     = azurerm_bastion_host.main.name == "custom-bas"
    error_message = "A custom Bastion name must override the generated name."
  }

  assert {
    condition     = azurerm_public_ip.pip.name == "custom-pip"
    error_message = "A custom public IP name must override the generated name."
  }

  assert {
    condition     = azurerm_bastion_host.main.ip_configuration[0].name == "custom-ipconfig-ipconfig"
    error_message = "A custom IP configuration name must override the generated name."
  }

  assert {
    condition     = azurerm_public_ip.pip.domain_name_label == "explicit-dns"
    error_message = "An explicit domain_name_label must take precedence over generated DNS labels."
  }

  assert {
    condition     = azurerm_bastion_host.main.location == "eastus" && azurerm_public_ip.pip.location == "eastus"
    error_message = "Bastion and public IP resources must use the selected resource group's location."
  }

  assert {
    condition     = azurerm_bastion_host.main.copy_paste_enabled == false && azurerm_bastion_host.main.file_copy_enabled == true && azurerm_bastion_host.main.ip_connect_enabled == true && azurerm_bastion_host.main.shareable_link_enabled == true && azurerm_bastion_host.main.tunneling_enabled == true
    error_message = "enable_* input variables must map to azurerm_bastion_host *_enabled arguments without consumer-visible renames."
  }

  assert {
    condition     = azurerm_public_ip.pip.tags.environment == "override" && azurerm_public_ip.pip.tags.owner == "platform" && azurerm_public_ip.pip.tags.workload == "workload"
    error_message = "Public IP tags must merge default tags with add_tags, with add_tags taking precedence."
  }

  assert {
    condition     = azurerm_bastion_host.main.tags.ResourceName == "custom-bas" && azurerm_bastion_host.main.tags.owner == "platform"
    error_message = "Bastion tags must include the lower-case ResourceName and add_tags entries."
  }

  assert {
    condition     = length(azurerm_management_lock.bastion_level_lock) == 1 && length(azurerm_management_lock.bastion_pip_level_lock) == 1
    error_message = "Resource locks must be created when enable_resource_locks is true."
  }
}

run "empty_custom_names_fall_through_and_locks_disabled" {
  command = plan

  variables {
    custom_bastion_name   = ""
    custom_public_ip_name = ""
    custom_ipconfig_name  = ""
    enable_resource_locks = false
    add_tags = {
      owner = "network"
    }
  }

  assert {
    condition     = azurerm_bastion_host.main.name == "generated-bastion"
    error_message = "An empty custom_bastion_name must fall through to the generated Bastion name."
  }

  assert {
    condition     = azurerm_public_ip.pip.name == "generated-pip"
    error_message = "An empty custom_public_ip_name must fall through to the generated public IP name."
  }

  assert {
    condition     = azurerm_bastion_host.main.ip_configuration[0].name == "generated-bastion-ipconfig"
    error_message = "An empty custom_ipconfig_name must fall through to the generated Bastion name."
  }

  assert {
    condition     = random_string.str.keepers.domain_name_label == "generated-bastion"
    error_message = "Generated DNS label entropy must be kept by the generated Bastion name when custom_bastion_name is empty."
  }

  assert {
    condition     = azurerm_bastion_host.main.copy_paste_enabled == true && azurerm_bastion_host.main.file_copy_enabled == null && azurerm_bastion_host.main.ip_connect_enabled == null && azurerm_bastion_host.main.shareable_link_enabled == null && azurerm_bastion_host.main.tunneling_enabled == null
    error_message = "Basic SKU must preserve default copy/paste and suppress Standard-only feature flags."
  }

  assert {
    condition     = length(azurerm_management_lock.bastion_level_lock) == 0 && length(azurerm_management_lock.bastion_pip_level_lock) == 0
    error_message = "Resource locks must not be created when enable_resource_locks is false."
  }
}
