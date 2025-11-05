# Cluster AKS público con outbound type LoadBalancer
resource "azurerm_kubernetes_cluster" "main" {
  name                    = var.cluster_name
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  dns_prefix              = var.dns_prefix
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = false # Cluster público
  tags                    = var.tags

  # Pool de nodos por defecto
  default_node_pool {
    name                 = "system"
    node_count           = 1
    vm_size              = var.node_vm_size
    type                 = "VirtualMachineScaleSets"
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 1
    max_pods             = 30
    os_disk_size_gb      = 128
    os_disk_type         = "Managed"

    # Configuración de red - Azure CNI Node Subnet (nodos y pods en la misma subnet)
    vnet_subnet_id = azurerm_subnet.aks.id

    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  # Configuración de red con Azure CNI y UDR
  network_profile {
    network_plugin    = "azure"
    network_mode      = "transparent"
    network_policy    = "azure"
    dns_service_ip    = "10.1.0.10"
    service_cidr      = "10.1.0.0/16"
    outbound_type     = "userDefinedRouting" # Tipo de salida UDR
    load_balancer_sku = "standard"

    # No se especifica load_balancer_profile para UDR
    # ya que el tráfico de salida se maneja mediante Route Table
  }

  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  # Azure AD integration
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = []
    azure_rbac_enabled     = true
  }

  # Configuración adicional
  api_server_access_profile {
    authorized_ip_ranges = ["0.0.0.0/0"] # Público - cambiar según necesidades de seguridad
  }

  # Monitor y logs
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.main.id
    msi_auth_for_monitoring_enabled = true
  }

  # Configuraciones de seguridad
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # HTTP application routing (opcional)
  http_application_routing_enabled = false

  depends_on = [
    azurerm_role_assignment.aks_network_contributor,
    azurerm_role_assignment.aks_vm_contributor,
    azurerm_role_assignment.aks_route_table_contributor,
    azurerm_subnet_route_table_association.aks_udr_association,
    azurerm_firewall.main
  ]
}

# Node pool adicional (opcional)
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  name                  = "additional"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D4s_v6"
  node_count            = 1
  auto_scaling_enabled  = true
  min_count             = 1
  max_count             = 2
  max_pods              = 30
  os_disk_size_gb       = 128
  # os_type               = "Linux"

  vnet_subnet_id = azurerm_subnet.aks.id

  node_labels = {
    "nodepool-type" = "additional"
    "environment"   = "dev"
  }

  tags = var.tags
}

# Log Analytics Workspace para monitoreo
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.cluster_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Role assignments para AKS
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

resource "azurerm_role_assignment" "aks_vm_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

# Role assignment adicional para Route Table
resource "azurerm_role_assignment" "aks_route_table_contributor" {
  scope                = azurerm_route_table.aks_udr.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}