resource "azurerm_virtual_machine_scale_set" "test" {
  name                 = "myvm-vmss"
  location             = "${azurerm_resource_group.test.location}"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  upgrade_policy_mode  = "Rolling"
  automatic_os_upgrade = true
  health_probe_id      = "${azurerm_lb_probe.test.id}"
  
  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches              = "PT0S"
  }
  
  sku {
    name = "Standard_D1_v2"
    tier = "Standard"
    capacity = 4
  }
  
  os_profile {
    computer_name_prefix = "myvm-vmss-vm"
    admin_username       = "myadmin"
    admin_password       = "Password12345"
  }
  
  os_profile_linux_config {
    disable_password_authentication = false
  }
  
  network_profile {
    name    = "web_ss_net_profile"
    primary = true
    
    ip_configuration {
      name                                   = "internal"
      subnet_id                              = "${azurerm_subnet.test.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.test.id}"]
      primary                                = true
    }     
  }
 
  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_autoscale_setting" "cpu_scaling" {
  name                = "autoscale-cpu"
  target_resource_id  = "${azurerm_virtual_machine_scale_set.test.id}"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  
  profile {
    name = "autoscale-cpu"
    
    capacity {
      default = 2
      minimum = 1 
      maximum = 100
    }
    
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = "${azurerm_virtual_machine_scale_set.test.id}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = "${azurerm_virtual_machine_scale_set.test.id}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 15
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }    
  }
}