# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {
  # Naming locals/constants
  name_prefix = lower(var.name_prefix)
  name_suffix = lower(var.name_suffix)

  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, module.mod_bastion_rg.*.resource_group_name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, module.mod_bastion_rg.*.resource_group_location, [""]), 0)

  custom_bastion_name   = var.custom_bastion_name == "" ? null : var.custom_bastion_name
  custom_public_ip_name = var.custom_public_ip_name == "" ? null : var.custom_public_ip_name
  custom_ipconfig_name  = var.custom_ipconfig_name == "" ? null : var.custom_ipconfig_name

  bastion_name     = coalesce(local.custom_bastion_name, data.popsrox_resource_name.bastion.result)
  bastion_pip_name = coalesce(local.custom_public_ip_name, data.popsrox_resource_name.bastion_pip.result)
}
