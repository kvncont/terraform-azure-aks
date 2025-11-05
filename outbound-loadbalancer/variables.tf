variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "rg-aks-kvncont"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "East US 2"
}

variable "cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
  default     = "aks-kvncont"
}

variable "dns_prefix" {
  description = "Prefijo DNS para el cluster AKS"
  type        = string
  default     = "akskvncont"
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

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "aks-kvncont"
    CreatedBy   = "terraform"
  }
}