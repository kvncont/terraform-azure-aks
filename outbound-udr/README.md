# Cluster AKS Público con Outbound LoadBalancer

Este proyecto despliega un cluster de Azure Kubernetes Service (AKS) público con las siguientes características:

- **Tipo de cluster**: Público (accesible desde Internet)
- **Outbound type**: LoadBalancer
- **CNI**: Azure CNI Node Subnet (nodos y pods en la misma subnet)
- **Escalado automático**: Habilitado en los node pools
- **Monitoreo**: Integrado con Log Analytics
- **Seguridad**: Azure RBAC habilitado

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    Resource Group                        │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │                    VNet                           │  │
│  │                 10.0.0.0/16                       │  │
│  │                                                   │  │
│  │  ┌───────────────────────────────────────────────┐ │  │
│  │  │           AKS Subnet (Nodes + Pods)          │ │  │
│  │  │              10.0.1.0/23                     │ │  │
│  │  │                                               │ │  │
│  │  │  [Node Pool] [Pod IPs] [LoadBalancer]        │ │  │
│  │  │         (Azure CNI Node Subnet)               │ │  │
│  │  └───────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌─────────────────┐                                   │
│  │ Log Analytics   │                                   │
│  │   Workspace     │                                   │
│  └─────────────────┘                                   │
└─────────────────────────────────────────────────────────┘
```

## Recursos Creados

### Red
- **Virtual Network**: Red principal con espacio de direcciones configurable
- **Subnet AKS**: Una sola subnet para nodos y pods (Azure CNI Node Subnet)
- **Network Security Group**: Con reglas básicas de seguridad
- **User Assigned Identity**: Para permisos del cluster

### AKS Cluster
- **Cluster público**: Accesible desde Internet
- **Outbound type**: LoadBalancer para conectividad saliente
- **Azure CNI Node Subnet**: Nodos y pods en la misma subnet
- **Node Pools**: Pool por defecto + pool adicional opcional
- **Auto-scaling**: Habilitado (1-5 nodos por defecto)
- **Azure RBAC**: Integración con Azure Active Directory

### Monitoreo
- **Log Analytics Workspace**: Para logs y métricas del cluster
- **Container Insights**: Monitoreo detallado de contenedores

## Uso

### 1. Configuración inicial

```bash
# Clonar el repositorio y navegar al directorio
cd outbound-loadbalancer

# Copiar y personalizar variables
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores específicos
```

### 2. Despliegue

```bash
# Inicializar Terraform
terraform init

# Revisar el plan de despliegue
terraform plan

# Aplicar la configuración
terraform apply
```

### 3. Conexión al cluster

```bash
# Obtener credenciales del cluster
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>

# Verificar conectividad
kubectl get nodes
kubectl get pods --all-namespaces
```

## Variables Principales

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `resource_group_name` | Nombre del grupo de recursos | `rg-aks-public-lb` |
| `location` | Región de Azure | `East US` |
| `cluster_name` | Nombre del cluster AKS | `aks-public-cluster` |
| `kubernetes_version` | Versión de Kubernetes | `1.28.3` |
| `node_count` | Número inicial de nodos | `3` |
| `node_vm_size` | Tamaño de VM de los nodos | `Standard_D2s_v3` |
| `vnet_address_space` | Espacio de direcciones VNet | `["10.0.0.0/16"]` |
| `aks_subnet_address_prefix` | Subnet para AKS (nodos y pods) | `10.0.1.0/23` |

## Outputs Importantes

- `aks_fqdn`: FQDN del cluster para acceso público
- `kube_config`: Configuración de kubectl (sensible)
- `aks_cluster_id`: ID único del cluster
- `vnet_id`: ID de la red virtual creada

## Características de Seguridad

### Red
- Network Security Group con reglas básicas
- Subnets separadas para nodos y pods
- Outbound LoadBalancer para conectividad controlada

### Cluster
- Azure RBAC habilitado
- Authorized IP ranges configurables
- User Assigned Identity con permisos mínimos necesarios
- Key Vault Secrets Provider habilitado

## Escalabilidad

- **Auto-scaling**: Los node pools escalan automáticamente entre min/max configurado
- **Node pools múltiples**: Soporte para diferentes tipos de cargas de trabajo
- **Azure CNI Node Subnet**: Optimiza el uso de IPs compartiendo subnet entre nodos y pods

## Monitoreo y Logs

- **Container Insights**: Monitoreo detallado de contenedores y pods
- **Log Analytics**: Centralización de logs del cluster
- **Métricas**: CPU, memoria, red y almacenamiento
- **Alertas**: Configurables sobre métricas de rendimiento

## Consideraciones de Costos

- **Load Balancer Standard**: Incluido para outbound connectivity
- **Log Analytics**: Cobra por ingesta de datos (30 días de retención)
- **Node pools**: Costo basado en VMs utilizadas
- **Public IP**: Para el Load Balancer del cluster

## Mantenimiento

```bash
# Actualizar versión de Kubernetes
terraform plan -var="kubernetes_version=1.29.0"
terraform apply

# Escalar nodos manualmente
terraform plan -var="node_count=5"
terraform apply

# Ver estado del cluster
kubectl cluster-info
kubectl get nodes -o wide
```

## Limpieza

```bash
# Eliminar todos los recursos
terraform destroy

# Confirmar eliminación
# NOTA: Esto eliminará TODOS los recursos creados
```

## Solución de Problemas

### Error de conectividad
```bash
# Verificar NSG rules
az network nsg rule list --resource-group <rg-name> --nsg-name <nsg-name>

# Verificar subnets
az network vnet subnet list --resource-group <rg-name> --vnet-name <vnet-name>
```

### Error de pods
```bash
# Verificar pod subnet
kubectl describe node <node-name>

# Verificar CNI
kubectl get pods -n kube-system | grep azure-cni
```

---

**Nota**: Este cluster es público y accesible desde Internet. Asegúrate de configurar las reglas de seguridad apropiadas según tus necesidades de seguridad.