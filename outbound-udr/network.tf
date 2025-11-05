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

# # Regla: Permitir tráfico de salida a Internet (necesario para UDR)
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

# Subnet para Azure Firewall (debe llamarse exactamente "AzureFirewallSubnet")
resource "azurerm_subnet" "firewall" {
  count                = var.enable_azure_firewall ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.firewall_subnet_address_prefix]
}

# Subnet para Azure Firewall Management (requerido para Basic SKU)
resource "azurerm_subnet" "firewall_management" {
  count                = var.enable_azure_firewall && var.firewall_sku_tier == "Basic" ? 1 : 0
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.firewall_management_subnet_address_prefix]
}

# Public IP para Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count               = var.enable_azure_firewall ? 1 : 0
  name                = "pip-azfw-${var.cluster_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# Public IP para Azure Firewall Management (requerido para Basic SKU)
resource "azurerm_public_ip" "firewall_management" {
  count               = var.enable_azure_firewall && var.firewall_sku_tier == "Basic" ? 1 : 0
  name                = "pip-azfw-mgmt-${var.cluster_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  count               = var.enable_azure_firewall ? 1 : 0
  name                = "azfw-${var.cluster_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = var.firewall_sku_name
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  # Management IP configuration (requerido para Basic SKU)
  dynamic "management_ip_configuration" {
    for_each = var.firewall_sku_tier == "Basic" ? [1] : []
    content {
      name                 = "management"
      subnet_id            = azurerm_subnet.firewall_management[0].id
      public_ip_address_id = azurerm_public_ip.firewall_management[0].id
    }
  }
}

# Firewall Policy
resource "azurerm_firewall_policy" "main" {
  count               = var.enable_azure_firewall ? 1 : 0
  name                = "azfw-policy-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.firewall_sku_tier
  tags                = var.tags

  # DNS proxy solo disponible en Standard/Premium, condicional para Basic
  dynamic "dns" {
    for_each = var.firewall_sku_tier != "Basic" ? [1] : []
    content {
      proxy_enabled = true
    }
  }

  # Threat Intelligence disponible en Standard/Premium
  threat_intelligence_mode = var.firewall_sku_tier != "Basic" ? "Alert" : "Off"
}

# Firewall Policy Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "aks_rules" {
  count              = var.enable_azure_firewall ? 1 : 0
  name               = "aks-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.main[0].id
  priority           = 500

  # Network Rules para AKS
  network_rule_collection {
    name     = "aks-network-rules"
    priority = 400
    action   = "Allow"

    # Permitir DNS
    rule {
      name                  = "AllowDNS"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["172.16.0.0/23"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    # Permitir NTP
    rule {
      name                  = "AllowNTP"
      protocols             = ["UDP"]
      source_addresses      = ["172.16.0.0/23"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }

  # Application Rules para FQDN específicos de AKS
  application_rule_collection {
    name     = "aks-application-rules"
    priority = 500
    action   = "Allow"

    rule {
      name = "AllowAKSRequiredFQDNs"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = ["172.16.0.0/23"]
      destination_fqdns = [
        # Azure AKS Global required FQDNs
        "*.azmk8s.io",
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "mcr-0001.mcr-msedge.net",
        "*.blob.core.windows.net",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        # "login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net",
        "packages.aks.azure.com",
        # Ubuntu        
        "*.ubuntu.com",
        "api.snapcraft.io",
        # DockerHub - Dominios necesarios para pull
        "registry-1.docker.io",             # Registry principal de DockerHub
        "index.docker.io",                  # Index de DockerHub
        "docker.io",                        # Dominio base de DockerHub
        "auth.docker.io",                   # Autenticación de DockerHub
        "cdn.docker.io",                    # CDN de DockerHub
        "production.cloudflare.docker.com", # CDN Cloudflare para DockerHub
        "download.docker.com",              # Descargas de Docker
        # Dominios adicionales de la infraestructura de Docker
        "*.docker.com", # Comodín para subdominios de Docker
        "*.docker.io",  # Comodín para subdominios de Docker.io
        # Dominios adicionales para registries
        "registry.hub.docker.com",
        # Cloudflare CDN específicos para DockerHub
        "*.r2.cloudflarestorage.com",
        "*.cloudflarestorage.com",
        # Extras
        "google.com",
        "*.google.com",
        # Microsoft telemetry y servicios adicionales
        "dc.services.visualstudio.com",
        "*.services.visualstudio.com",
        "vortex.data.microsoft.com",
        "*.data.microsoft.com",
        "go.microsoft.com",
        "*.microsoft.com",
        # OpenAI y servicios de IA (si se usan)
        "*.openai.com",
        "api.openai.com",
        # Dominios de testing para verificar SNAT
        "httpbin.org",
        "ifconfig.me",
        "icanhazip.com",
      ]
    }
  }
}

# Route Table para UDR
resource "azurerm_route_table" "aks_udr" {
  name                = "rt-${var.cluster_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Ruta específica para AzureActiveDirectory - directo a Internet
resource "azurerm_route" "azure_ad_route" {
  name                = "azure-ad-to-internet"
  resource_group_name = azurerm_resource_group.main.name
  route_table_name    = azurerm_route_table.aks_udr.name
  address_prefix      = "AzureActiveDirectory"
  next_hop_type       = "Internet"
}

# Ruta específica para AzureCloud East US 2 - directo a Internet
resource "azurerm_route" "azure_cloud_eastus2_route" {
  name                = "azure-cloud-eastus2-to-internet"
  resource_group_name = azurerm_resource_group.main.name
  route_table_name    = azurerm_route_table.aks_udr.name
  address_prefix      = "AzureCloud.eastus2"
  next_hop_type       = "Internet"
}

# Ruta específica para AzureCloud Central US - directo a Internet
resource "azurerm_route" "azure_cloud_centralus_route" {
  name                = "azure-cloud-centralus-to-internet"
  resource_group_name = azurerm_resource_group.main.name
  route_table_name    = azurerm_route_table.aks_udr.name
  address_prefix      = "AzureCloud.centralus"
  next_hop_type       = "Internet"
}

# Ruta por defecto hacia Azure Firewall o Internet
resource "azurerm_route" "default_route" {
  name                   = var.enable_azure_firewall ? "default-to-firewall" : "default-to-internet"
  resource_group_name    = azurerm_resource_group.main.name
  route_table_name       = azurerm_route_table.aks_udr.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = var.enable_azure_firewall ? "VirtualAppliance" : "Internet"
  next_hop_in_ip_address = var.enable_azure_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
}

# Asociar Route Table con la subnet de AKS
resource "azurerm_subnet_route_table_association" "aks_udr_association" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.aks_udr.id
}

# Identity para AKS
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "id-${var.cluster_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags
}
