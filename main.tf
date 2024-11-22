# Create Azure Virtual Desktop host pool
module "avm_res_desktopvirtualization_hostpool" {
  source                                             = "Azure/avm-res-desktopvirtualization-hostpool/azurerm"
  version                                            = "0.2.1"
  enable_telemetry                                   = var.enable_telemetry
  resource_group_name                                = var.resource_group_name
  virtual_desktop_host_pool_type                     = var.virtual_desktop_host_pool_type
  virtual_desktop_host_pool_location                 = var.virtual_desktop_host_pool_location
  virtual_desktop_host_pool_load_balancer_type       = var.virtual_desktop_host_pool_load_balancer_type
  virtual_desktop_host_pool_resource_group_name      = var.resource_group_name
  virtual_desktop_host_pool_name                     = var.virtual_desktop_host_pool_name
  virtual_desktop_host_pool_custom_rdp_properties    = var.virtual_desktop_host_pool_custom_rdp_properties
  virtual_desktop_host_pool_maximum_sessions_allowed = var.virtual_desktop_host_pool_maximum_sessions_allowed
  virtual_desktop_host_pool_start_vm_on_connect      = var.virtual_desktop_host_pool_start_vm_on_connect
  virtual_desktop_host_pool_friendly_name            = var.virtual_desktop_host_pool_friendly_name
  virtual_desktop_host_pool_scheduled_agent_updates = {
    enabled = "true"
    schedule = tolist([{
      day_of_week = "Sunday"
      hour_of_day = 0
    }])
  }
  diagnostic_settings = {
    to_law = {
      name                  = "to-law"
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }
}

# Registration information for the host pool.
resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  expiration_date = timeadd(timestamp(), var.registration_expiration_period)
  hostpool_id     = module.avm_res_desktopvirtualization_hostpool.resource.id

  lifecycle {
    ignore_changes = [
      expiration_date,
      hostpool_id,
    ]
  }
}

# Create Azure Virtual Desktop application group
module "avm_res_desktopvirtualization_applicationgroup" {
  source                                                         = "Azure/avm-res-desktopvirtualization-applicationgroup/azurerm"
  version                                                        = "0.1.5"
  enable_telemetry                                               = var.enable_telemetry
  virtual_desktop_application_group_name                         = var.virtual_desktop_application_group_name
  virtual_desktop_application_group_type                         = var.virtual_desktop_application_group_type
  virtual_desktop_application_group_host_pool_id                 = module.avm_res_desktopvirtualization_hostpool.resource.id
  virtual_desktop_application_group_resource_group_name          = var.resource_group_name
  virtual_desktop_application_group_location                     = var.virtual_desktop_application_group_location
  virtual_desktop_application_group_default_desktop_display_name = var.virtual_desktop_application_group_default_desktop_display_name
  virtual_desktop_application_group_description                  = var.virtual_desktop_application_group_description
  virtual_desktop_application_group_friendly_name                = var.virtual_desktop_application_group_friendly_name
  virtual_desktop_application_group_tags                         = local.tags
}

# Create Azure Virtual Desktop workspace
module "avm_res_desktopvirtualization_workspace" {
  source                                        = "Azure/avm-res-desktopvirtualization-workspace/azurerm"
  version                                       = "0.1.7"
  virtual_desktop_workspace_location            = var.virtual_desktop_workspace_location
  virtual_desktop_workspace_description         = var.virtual_desktop_workspace_description
  virtual_desktop_workspace_resource_group_name = var.resource_group_name
  resource_group_name                           = var.resource_group_name
  virtual_desktop_workspace_name                = var.virtual_desktop_workspace_name
  virtual_desktop_workspace_friendly_name       = var.virtual_desktop_workspace_friendly_name
  tags                                          = local.tags
  diagnostic_settings = {
    to_law = {
      name                  = "to-law"
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workappgrassoc" {
  application_group_id = module.avm_res_desktopvirtualization_applicationgroup.resource.id
  workspace_id         = module.avm_res_desktopvirtualization_workspace.resource.id
}


resource "random_uuid" "example" {}
# Create Azure Virtual Desktop scaling plan
module "avm_res_desktopvirtualization_scaling_plan" {
  source                                           = "Azure/avm-res-desktopvirtualization-scalingplan/azurerm"
  enable_telemetry                                 = var.enable_telemetry
  version                                          = "0.1.4"
  virtual_desktop_scaling_plan_name                = var.virtual_desktop_scaling_plan_name
  virtual_desktop_scaling_plan_location            = var.virtual_desktop_scaling_plan_location
  virtual_desktop_scaling_plan_resource_group_name = var.resource_group_name
  virtual_desktop_scaling_plan_time_zone           = var.virtual_desktop_scaling_plan_time_zone
  virtual_desktop_scaling_plan_description         = var.virtual_desktop_scaling_plan_description
  virtual_desktop_scaling_plan_tags                = local.tags
  virtual_desktop_scaling_plan_host_pool = toset(
    [
      {
        hostpool_id          = module.avm_res_desktopvirtualization_hostpool.resource.id
        scaling_plan_enabled = true
      }
    ]
  )
  virtual_desktop_scaling_plan_schedule = var.virtual_desktop_scaling_plan_schedule
}

