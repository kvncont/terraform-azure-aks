variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "rg-aks-kvncont-outbound-udr"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "East US 2"
}

variable "cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
  default     = "aks-kvncont-outbound-udr"
}

variable "dns_prefix" {
  description = "Prefijo DNS para el cluster AKS"
  type        = string
  default     = "aks-kvncont-outbound-udr"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.32.7"
}

variable "node_count" {
  description = "Número inicial de nodos"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "Tamaño de las VMs de los nodos"
  type        = string
  default     = "Standard_D2s_v6"
}

variable "vnet_address_space" {
  description = "Espacio de direcciones de la VNet"
  type        = list(string)
  default     = ["172.16.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Prefijo de direcciones para la subnet de AKS (nodos y pods)"
  type        = string
  default     = "172.16.0.0/23"
}

variable "firewall_subnet_address_prefix" {
  description = "Prefijo de direcciones para AzureFirewallSubnet (debe ser /26 o mayor)"
  type        = string
  default     = "172.16.2.0/26"
}

variable "firewall_management_subnet_address_prefix" {
  description = "Prefijo de direcciones para AzureFirewallManagementSubnet (requerido para Basic SKU)"
  type        = string
  default     = "172.16.3.0/26"
}

variable "enable_azure_firewall" {
  description = "Habilitar Azure Firewall como NVA"
  type        = bool
  default     = true
}

variable "firewall_sku_name" {
  description = "SKU del Azure Firewall"
  type        = string
  default     = "AZFW_VNet"
  validation {
    condition = contains(["AZFW_VNet", "AZFW_Hub"], var.firewall_sku_name)
    error_message = "El SKU debe ser AZFW_VNet o AZFW_Hub."
  }
}

variable "firewall_sku_tier" {
  description = "Tier del Azure Firewall"
  type        = string
  default     = "Basic"
  validation {
    condition = contains(["Standard", "Premium", "Basic"], var.firewall_sku_tier)
    error_message = "El tier debe ser Standard, Premium o Basic."
  }
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "aks-kvncont-outbound-udr"
    CreatedBy   = "terraform"
  }
}