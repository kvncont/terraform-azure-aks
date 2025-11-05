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

# Outputs adicionales para UDR
output "route_table_id" {
  description = "ID de la Route Table para UDR"
  value       = azurerm_route_table.aks_udr.id
}

output "default_route_name" {
  description = "Nombre de la ruta por defecto"
  value       = azurerm_route.default_route.name
}

output "azure_ad_route_name" {
  description = "Nombre de la ruta específica para AzureActiveDirectory"
  value       = azurerm_route.azure_ad_route.name
}

output "azure_cloud_eastus2_route_name" {
  description = "Nombre de la ruta específica para AzureCloud.eastus2"
  value       = azurerm_route.azure_cloud_eastus2_route.name
}

output "azure_cloud_centralus_route_name" {
  description = "Nombre de la ruta específica para AzureCloud.centralus"
  value       = azurerm_route.azure_cloud_centralus_route.name
}

# Outputs para monitoreo de logs del firewall
output "firewall_logs_queries" {
  description = "Consultas KQL para monitorear logs del Azure Firewall"
  value = <<-EOT
# Consultas para ejecutar en Log Analytics:

# 1. Ver todos los logs de reglas de aplicación (últimas 24h)
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| where TimeGenerated > ago(24h)
| order by TimeGenerated desc
| limit 100

# 2. Ver tráfico denegado por reglas de aplicación
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| where msg_s contains "Deny"
| project TimeGenerated, msg_s
| order by TimeGenerated desc

# 3. Ver tráfico permitido desde AKS subnet
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule" or Category == "AzureFirewallNetworkRule"
| where msg_s contains "172.16.0"
| project TimeGenerated, Category, msg_s
| order by TimeGenerated desc

# 4. Ver tráfico hacia dominios específicos
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| where msg_s contains "google.com" or msg_s contains "microsoft.com"
| project TimeGenerated, msg_s
| order by TimeGenerated desc

# 5. Estadísticas de tráfico por acción
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| extend Action = case(msg_s contains "Allow", "Allow", msg_s contains "Deny", "Deny", "Other")
| summarize Count = count() by Action
EOT
}

output "firewall_monitoring_commands" {
  description = "Comandos para monitorear el firewall en tiempo real"
  value = <<-EOT
# Comandos Azure CLI para monitorear:

# Ver logs en tiempo real (Application Rules)
az monitor activity-log list \
  --resource-group ${azurerm_resource_group.main.name} \
  --max-events 50 \
  --query "[?contains(resourceId, 'azfw-')]" \
  --output table

# Consultar logs específicos con Azure CLI
az monitor log-analytics query \
  --workspace ${azurerm_log_analytics_workspace.main.workspace_id} \
  --analytics-query "AzureDiagnostics | where Category == 'AzureFirewallApplicationRule' | order by TimeGenerated desc | limit 20"

# Ver métricas del firewall
az monitor metrics list \
  --resource ${var.enable_azure_firewall ? azurerm_firewall.main[0].id : "N/A"} \
  --metric "ApplicationRuleHit,NetworkRuleHit" \
  --output table
EOT
}



# Comandos de conexión al cluster
output "kubectl_connect_command" {
  description = "Comando para conectarse al cluster AKS"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing"
}

output "kubectl_connect_admin_command" {
  description = "Comando para conectarse al cluster AKS con permisos de administrador"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --admin --overwrite-existing"
}

# Comandos útiles adicionales
output "aks_browse_command" {
  description = "Comando para abrir el dashboard de Kubernetes (si está habilitado)"
  value       = "az aks browse --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "cluster_info_command" {
  description = "Comando para obtener información del cluster"
  value       = "kubectl cluster-info"
}

output "quick_start_commands" {
  description = "Comandos de inicio rápido después del despliegue"
  value = <<-EOT
# Conectarse al cluster
${azurerm_resource_group.main.name != "" ? "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --admin --overwrite-existing" : ""}

# Verificar conexión
kubectl get nodes

# Crear pod de prueba de red
kubectl run netshoot --rm -i --tty --image nicolaka/netshoot -- /bin/bash
EOT
}

output "outbound_type" {
  description = "Tipo de salida configurado para AKS"
  value       = "userDefinedRouting"
}

# Outputs de Azure Firewall
output "firewall_id" {
  description = "ID del Azure Firewall (si está habilitado)"
  value       = var.enable_azure_firewall ? azurerm_firewall.main[0].id : null
}

output "firewall_private_ip" {
  description = "IP privada del Azure Firewall (si está habilitado)"
  value       = var.enable_azure_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
}

output "firewall_public_ip" {
  description = "IP pública del Azure Firewall (si está habilitado)"
  value       = var.enable_azure_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "firewall_management_public_ip" {
  description = "IP pública de management del Azure Firewall (si está habilitado con Basic SKU)"
  value       = var.enable_azure_firewall && var.firewall_sku_tier == "Basic" ? azurerm_public_ip.firewall_management[0].ip_address : null
}

output "firewall_policy_id" {
  description = "ID de la Firewall Policy (si está habilitado)"
  value       = var.enable_azure_firewall ? azurerm_firewall_policy.main[0].id : null
}