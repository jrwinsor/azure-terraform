locals {
  frontend_ip_configuration_name = "internal"
}

resource "azurerm_lb" "test" {
  name                = "test-lb"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.test.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "test" {
  name                = "backend"
  resource_group_name = "${azurerm_resource_group.test.name}"
  loadbalancer_id     = "${azurerm_lb.test.id}"
}

resource "azurerm_lb_probe" "test" {
  name                = "ssh-running-probe"
  resource_group_name = "${azurerm_resource_group.test.name}"
  loadbalancer_id     = "${azurerm_lb.test.id}"
  port                = 22
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "example" {
  resource_group_name            = "${azurerm_resource_group.test.name}"
  loadbalancer_id                = "${azurerm_lb.test.id}"
  probe_id                       = "${azurerm_lb_probe.test.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.test.id}"
  frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
}