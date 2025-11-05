# Configuración de diagnóstico para Azure Firewall logs
resource "azurerm_monitor_diagnostic_setting" "firewall_diagnostics" {
  count                      = var.enable_azure_firewall ? 1 : 0
  name                       = "firewall-diagnostics"
  target_resource_id         = azurerm_firewall.main[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Logs de reglas de aplicación
  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  # Logs de reglas de red
  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  # Logs de DNS proxy (solo disponible en Standard/Premium)
  dynamic "enabled_log" {
    for_each = var.firewall_sku_tier != "Basic" ? [1] : []
    content {
      category = "AzureFirewallDnsProxy"
    }
  }

  # Métricas del firewall
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Configuración de diagnóstico para AKS cluster
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  name                       = "aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Logs de AKS
  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "guard"
  }

  # Métricas de AKS
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Configuración de diagnóstico para Network Security Group
resource "azurerm_monitor_diagnostic_setting" "nsg_diagnostics" {
  name                       = "nsg-diagnostics"
  target_resource_id         = azurerm_network_security_group.aks_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Logs de NSG
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# Azure Monitor Container Insights para AKS
resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}