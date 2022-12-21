resource "azurerm_public_ip" "lb_pip" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "LoadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_bap" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackendAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "bapa" {
  count = var.number_of_vms
  network_interface_id    = azurerm_network_interface.vm_nics[count.index].id
  ip_configuration_name   = "ip-config-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_bap.id
}

resource "azurerm_lb_probe" "lb_probe_80" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "http-running-probe"
  port            = 80
}

resource "azurerm_lb_rule" "lb_rule_80" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule_80"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_bap.id]
  probe_id = azurerm_lb_probe.lb_probe_80.id
}