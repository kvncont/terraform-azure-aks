# Grupo de recursos
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Red virtual
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.cluster_name}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Subnet para AKS (nodos y pods en la misma subnet - Azure CNI Node Subnet)
resource "azurerm_subnet" "aks" {
  name                 = "subnet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_address_prefix]

  # delegation {
  #   name = "aks-delegation"
  #   service_delegation {
  #     actions = [
  #       "Microsoft.Network/virtualNetworks/subnets/join/action",
  #     ]
  #     name = "Microsoft.ContainerService/managedClusters"
  #   }
  # }
}

# NSG para la subnet de AKS
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "nsg-${var.cluster_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Regla: Permitir comunicación entre nodos del cluster (intra-subnet)
# resource "azurerm_network_security_rule" "allow_intra_subnet" {
#   name                        = "AllowIntraSubnet"
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = var.aks_subnet_address_prefix
#   destination_address_prefix  = var.aks_subnet_address_prefix
#   resource_group_name         = azurerm_resource_group.main.name
#   network_security_group_name = azurerm_network_security_group.aks_nsg.name
# }

# # Regla: Permitir Load Balancer (Azure Load Balancer probe)
# resource "azurerm_network_security_rule" "allow_azure_load_balancer" {
#   name                        = "AllowAzureLoadBalancer"
#   priority                    = 200
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "AzureLoadBalancer"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.main.name
#   network_security_group_name = azurerm_network_security_group.aks_nsg.name
# }

# # Regla: Permitir tráfico de salida a Internet
# resource "azurerm_network_security_rule" "allow_internet_outbound" {
#   name                        = "AllowInternetOutbound"
#   priority                    = 100
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "Internet"
#   resource_group_name         = azurerm_resource_group.main.name
#   network_security_group_name = azurerm_network_security_group.aks_nsg.name
# }

# # Regla: Denegar todo el resto del tráfico entrante
# resource "azurerm_network_security_rule" "deny_all_inbound" {
#   name                        = "DenyAllInbound"
#   priority                    = 4096
#   direction                   = "Inbound"
#   access                      = "Deny"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.main.name
#   network_security_group_name = azurerm_network_security_group.aks_nsg.name
# }

# Asociar NSG con la subnet de AKS
resource "azurerm_subnet_network_security_group_association" "aks_nsg_association" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# Identity para AKS
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "id-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags
}