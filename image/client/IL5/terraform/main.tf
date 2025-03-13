provider "azurerm" {
  subscription_id = "1e8fce59-3cbe-40e7-a5ff-d97980f491e3"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

######################
# Azure IL5 Gov
# Resource Groups: 
# rg-vram-va-dev-001
# rg-vram-va-test-001
# rg-vram-va-prod-001
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

variable "admin_username" {
  default = "dd"
}

variable "admin_password" {
  default = "DigitalData123#"
}

# Update for Navy Image ID
variable "custom_image_id" {
  default = "/subscriptions/1e8fce59-3cbe-40e7-a5ff-d97980f491e3/resourcegroups/scope-DEV-ResourceGroup-v8/providers/Microsoft.Compute/galleries/BaseImagev7/images/BaseImageV7/versions/0.0.7"
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

resource "azurerm_subnet" "pgs" {
  name                 = "scope-${var.environment}-pgs-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.main.name
  address_prefixes     = ["10.21.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Application Security Gateway with WAF v2 for SIPR connection via DoDIN

resource "azurerm_virtual_network" "vnet" {
  name                = "scope-${var.environment}-VNet"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = var.scope_address_space
}

resource "azurerm_network_security_group" "default" {
  name                = "scope-${var.environment}-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "default"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
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



#
# Azure Load Balancers
#
# k8s Control Plane Load Balancer
resource "azurerm_lb" "lb1" {
  name                = "scope-${var.environment}-k8s-ingress-LoadBalancer"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    private_ip_address = "10.21.1.40"
    private_ip_address_allocation = "Static"
    private_ip_address_version = "IPv4"
    subnet_id = azurerm_subnet.backend.id
  }
}

# k8s Control Plane Load Balancer  Health Probe
resource "azurerm_lb_probe" "lb1" {
  loadbalancer_id = azurerm_lb.lb1.id
  name            = "k8s-health-probe"
  port            = 6443
}

# k8s Control Plane Load Balancer  Rule
resource "azurerm_lb_rule" "lb1" {
  loadbalancer_id                = azurerm_lb.lb1.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
}

# k8s Control Plane Load Balancer Backend Address Pool
resource "azurerm_lb_backend_address_pool" "lb1_pool" {
  name                = "scope-${var.environment}-Pool"
  loadbalancer_id     = azurerm_lb.lb1.id
}

# k8s Ingress Load Balancer Public IP
resource "azurerm_public_ip" "lb2_pip" {
  name                = "scope-${var.environment}-lb2-pip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku = "Standard"
}

# k8s Ingress Load Balancer 
resource "azurerm_lb" "lb2" {
  name                = "scope-${var.environment}-ingressLB"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb2_pip.id
  }
}

# k8s Ingress Load Balancer Backend Address Pool 
resource "azurerm_lb_backend_address_pool" "lb2_pool" {
  name                = "scope-${var.environment}-BackendPool"
  loadbalancer_id     = azurerm_lb.lb2.id
} 

#
# k8s Cluster & Ansible Master - Virtual Machines
#

# Network Interface for VMs
resource "azurerm_network_interface" "vm_nic" {
  count               = 4
  name                = "scope-${var.environment}-NIC${count.index + 1}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

#k8s-ha-m3 NIC
resource "azurerm_network_interface" "vm_nic_2"  {
  name                = "scope-${var.environment}-NIC5"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  ip_configuration {
    primary                       = true
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "internal2"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# First Master Node
resource "azurerm_linux_virtual_machine" "vm1" {
  name                 = "k8s-ha-m-3"
  computer_name        = "k8s-ha-m-3"
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.vm_nic_2.id]
  size                 = "Standard_D2s_v3"
  disable_password_authentication = false
  secure_boot_enabled = true

  source_image_id = var.custom_image_id
  admin_username = var.admin_username
  admin_password = var.admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 512
  }

}

# k8s Control Plane Cluster Nodes 

resource "azurerm_linux_virtual_machine" "cps" {
  count                = 2
  name                 = "k8s-ha-m-${count.index + 1}"
  computer_name        = "k8s-ha-m-${count.index + 1}"
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.vm_nic[count.index].id]
  size                 = "Standard_D2s_v3"
  disable_password_authentication = false
  secure_boot_enabled = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 512

  }

  source_image_id = var.custom_image_id
  admin_username = var.admin_username
  admin_password = var.admin_password
}

# k8s Control Plane Cluster Nodes 
# Associate VMs with Load Balancer 1 (first 3 VMs)
resource "azurerm_network_interface_backend_address_pool_association" "lb1_assoc" {
  count                    = 3
  network_interface_id     = azurerm_network_interface.vm_nic[count.index].id
  ip_configuration_name    = "internal"
  backend_address_pool_id  = azurerm_lb_backend_address_pool.lb1_pool.id
}

# k8s Worker Cluster Nodes 
# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "scope-${var.environment}-VMSS"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  upgrade_mode        = "Automatic"
  sku = "Standard_D2s_v3"
  disable_password_authentication = false
  instances = 2


  network_interface {
    name    = "scope-${var.environment}-VMSSNIC"
    primary = true
    ip_configuration {
      name      = "scope-${var.environment}-ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.backend.id
      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.lb2_pool.id,
      ]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 512

  }

  source_image_id = var.custom_image_id
  secure_boot_enabled = true

  admin_username = var.admin_username
  admin_password = var.admin_password

  computer_name_prefix = "k8s-w-"
}

resource "azurerm_private_dns_zone" "default" {
  name                = "${var.environment}-pdz.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name

}


resource "random_password" "pass" {
  length = 20
}

resource "azurerm_postgresql_flexible_server" "default" {
  name                   = "scope-postgres-server"
  resource_group_name    = data.azurerm_resource_group.main.name
  location               = data.azurerm_resource_group.main.location
  version                = "16"
  public_network_access_enabled = false
  delegated_subnet_id    = azurerm_subnet.pgs.id
  private_dns_zone_id    = azurerm_private_dns_zone.default.id
  administrator_login    = "adminTerraform"
  administrator_password = random_password.pass.result
  zone                   = "1"
  storage_mb             = 262144
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7

}

resource "azurerm_postgresql_flexible_server_database" "default" {
  name      = "scope-${var.environment}-db"
  server_id = azurerm_postgresql_flexible_server.default.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}