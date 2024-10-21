provider "azurerm" {
  subscription_id = "1e8fce59-3cbe-40e7-a5ff-d97980f491e3"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

######################
# Variables
variable "location" {
  default = "East US"
}
variable "environment" {
  default = "DEV"
}
variable "scope_address_space" {
  default = ["10.21.0.0/16"]
}
variable "scope_frontend_subnet_prefix" {
  default = ["10.21.0.0/24"]
}

variable "scope_backend_subnet_prefix" {
  default = ["10.21.1.0/24"]
}

# Use the Existing Provided Resource
data "azurerm_resource_group" "main" {
  name = "scope-${var.environment}-ResourceGroup-v9"
}
output "id" {
  value = data.azurerm_resource_group.main.id
}

variable "backend_address_pool_name" {
    default = "scope-BackendPool"
}

variable "frontend_port_name" {
    default = "scope-FrontendPort"
}

variable "frontend_ip_configuration_name" {
    default = "scope-AGIPConfig"
}

variable "http_setting_name" {
    default = "scope-HTTPsetting"
}

variable "listener_name" {
    default = "scope-Listener"
}

variable "request_routing_rule_name" {
    default = "scope-RoutingRule"
}

# Application Security Gateway with WAF v2 for SIPR connection via DoDIN

resource "azurerm_virtual_network" "vnet" {
  name                = "scope-${var.environment}-VNet"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = var.scope_address_space
}

resource "azurerm_subnet" "frontend" {
  name                 = "scope-${var.environment}-AGSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.scope_frontend_subnet_prefix
}

resource "azurerm_subnet" "backend" {
  name                 = "scope-${var.environment}-BackendSubnet"
  resource_group_name = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.scope_backend_subnet_prefix
}

resource "azurerm_public_ip" "pip" {
  name                = "scope-${var.environment}-AGPublicIPAddress"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_application_gateway" "main" {
  name                = "scope-${var.environment}-AppGateway"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "scope-${var.environment}-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name
  }

  backend_http_settings {
    name                  = var.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = var.http_setting_name
    priority                   = 1
  }
}

resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "nic-${count.index+1}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "nic-ipconfig-${count.index+1}"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "nic-ipconfig-${count.index+1}"
  backend_address_pool_id = one(azurerm_application_gateway.main.backend_address_pool).id
}

output "gateway_frontend_ip" {
  value = "http://${azurerm_public_ip.pip.ip_address}"
}


