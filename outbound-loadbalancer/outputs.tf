output "resource_group_name" {
  description = "Nombre del grupo de recursos creado"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Nombre del cluster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID del cluster AKS"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_fqdn" {
  description = "FQDN del cluster AKS"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_kubernetes_version" {
  description = "Versión de Kubernetes del cluster"
  value       = azurerm_kubernetes_cluster.main.kubernetes_version
}

output "aks_node_resource_group" {
  description = "Grupo de recursos de los nodos AKS"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "vnet_id" {
  description = "ID de la red virtual"
  value       = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  description = "ID de la subnet de AKS (nodos y pods)"
  value       = azurerm_subnet.aks.id
}

output "aks_identity_principal_id" {
  description = "Principal ID de la identidad de AKS"
  value       = azurerm_user_assigned_identity.aks_identity.principal_id
}

output "aks_identity_client_id" {
  description = "Client ID de la identidad de AKS"
  value       = azurerm_user_assigned_identity.aks_identity.client_id
}

output "log_analytics_workspace_id" {
  description = "ID del workspace de Log Analytics"
  value       = azurerm_log_analytics_workspace.main.id
}

output "kube_config" {
  description = "Configuración de kubectl (sensible)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "client_certificate" {
  description = "Certificado del cliente (sensible)"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Clave del cliente (sensible)"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificado CA del cluster (sensible)"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate
  sensitive   = true
}

output "host" {
  description = "Host del cluster Kubernetes"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
  sensitive   = true
}