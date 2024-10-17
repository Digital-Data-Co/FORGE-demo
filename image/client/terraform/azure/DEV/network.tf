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
  default = ["10.0.0.0/24"]
}


variable "inside_subnet_prefix" {
  default = "10.0.0.32/27"
}


# Use the Existing Provided Resource
data "azurerm_resource_group" "main" {
  name = "scope-${var.environment}-ResourceGroup-v8"
}

output "id" {
  value = data.azurerm_resource_group.main.id
}


resource "azurerm_container_registry" "acr" {
  name                = "containerRegistry1"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = "West US" 
    zone_redundancy_enabled = true
    tags                    = {}
  }
}


# Primary Virtual Network
resource "azurerm_virtual_network" "primary" {
  name                = "scope-${var.environment}-primary-vnet"
  address_space       = var.scope_address_space
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}


# Application Security Gateway with WAF v2 for SIPR connection via DoDIN
resource "azurerm_public_ip" "main" {
  name                = "scope-${var.environment}-main-pip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.primary.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.primary.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.primary.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.primary.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.primary.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.primary.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.primary.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "main-appgateway"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.inside.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.main.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

}

# Bastion

#resource "azurerm_public_ip" "bastion" {
#  name                = "scope-${var.environment}-pip"
#  location            = data.azurerm_resource_group.main.location
#  resource_group_name = data.azurerm_resource_group.main.name
#  allocation_method   = "Static"
#  sku                 = "Standard"
#}

#resource "azurerm_virtual_network" "bastion" {
#  name                = "BastionVNet"
#  address_space       = ["10.0.0.224/27"]
#  location            = data.azurerm_resource_group.main.location
#  resource_group_name = data.azurerm_resource_group.main.name
#}

#resource "azurerm_subnet" "bastion" {
#  name                 = "AzureBastionSubnet"
#  resource_group_name  = data.azurerm_resource_group.main.name
#  virtual_network_name = azurerm_virtual_network.bastion.name
#  address_prefixes     = ["10.0.0.224/27"]
#}


#resource "azurerm_bastion_host" "bastion" {
#  name                = "scope-${var.environment}-bastion"
#  location            = data.azurerm_resource_group.main.location
#  resource_group_name = data.azurerm_resource_group.main.name
#  tunneling_enabled = true
#  sku = "Standard"
  
# ip_configuration {
#    name                 = "configuration"
#    subnet_id            = azurerm_subnet.bastion.id
#    public_ip_address_id = azurerm_public_ip.primary.id
#  }

#}


# Inside Subnet - Will be created by Digital Data
resource "azurerm_subnet" "inside" {
  name                 = "scope-${var.environment}-inside-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.primary.name
  address_prefixes     = [var.inside_subnet_prefix]
}

# Inside Network Security Group - Will be created by Digital Data
resource "azurerm_network_security_group" "inside" {
  name                = "scope-${var.environment}-inside-NSG"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Inside Route Table - Will be created by Digital Data
resource "azurerm_route_table" "inside" {
  name                          = "scope-${var.environment}-inside-routetable"
  location                      = data.azurerm_resource_group.main.location
  resource_group_name           = data.azurerm_resource_group.main.name
  #disable_bgp_route_propagation = false

  route {
    name           = "inside-route"
    address_prefix = "${var.inside_subnet_prefix}"
    next_hop_type  = "VnetLocal"
  }
}
resource "azurerm_subnet_route_table_association" "inside" {
  subnet_id      = azurerm_subnet.inside.id
  route_table_id = azurerm_route_table.inside.id
}


