---
name: opentofu-kubernetes-explorer
description: Explore and manage Kubernetes clusters and resources using OpenTofu/Terraform
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: container-orchestration
---

## What I do

I guide you through managing Kubernetes clusters and resources using Kubernetes provider for OpenTofu/Terraform.

- **Cluster Management**: Deploy and manage Kubernetes clusters
- **Resource Deployment**: Create pods, deployments, services, and configmaps
- **Ingress and Networking**: Configure ingress controllers and network policies
- **Storage**: Create and manage persistent volumes and storage classes
- **Helm Charts**: Deploy Helm charts for complex applications

## When to use me

Use when:
- Automating Kubernetes resource management as code
- Deploying applications to Kubernetes clusters
- Managing Kubernetes configuration (ConfigMaps, Secrets)
- Configuring ingress controllers and load balancers
- Setting up persistent storage and storage classes
- Deploying Helm charts for application packages

**Note**: OpenTofu and Terraform are used interchangeably throughout this skill. OpenTofu is an open-source implementation of Terraform and maintains full compatibility with Terraform providers.

## Prerequisites

- OpenTofu CLI installed: https://opentofu.org/docs/intro/install/
- Kubernetes cluster running (EKS, GKE, AKS, or self-managed)
- kubectl installed for local testing
- Valid kubeconfig file
- Basic Kubernetes knowledge (pods, services, deployments)

## Steps

### Step 1: Configure Provider

Create `versions.tf`:

```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
  }
}
```

Create `provider.tf`:

```hcl
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
```

**Connection methods**:
- Default kubeconfig: `config_path = "~/.kube/config"`
- Config context: `config_context = "my-cluster-context"`
- EKS: Use `host`, `cluster_ca_certificate`, `token` with AWS data sources

### Step 2: Create Namespace

```hcl
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
    labels = {
      app       = var.application_name
      managedBy = "terraform"
      environment = var.environment
    }
  }
}
```

### Step 3: Create ConfigMap and Secret

```hcl
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    "config.json" = jsonencode({
      port = 8080
      env  = var.environment
    })
  }
}

resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    "database-password" = var.database_password
  }

  type = "Opaque"
}
```

### Step 4: Create Deployment

```hcl
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.application_name
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = { app = var.application_name }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = var.application_name }
    }

    template {
      metadata {
        labels = { app = var.application_name }
      }

      spec {
        container {
          name  = "app"
          image = var.container_image

          port { container_port = 8080 }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret.metadata[0].name
                key  = "database-password"
              }
            }
          }

          resources {
            limits = { cpu = "500m", memory = "512Mi" }
            requests = { cpu = "250m", memory = "256Mi" }
          }

          liveness_probe {
            http_get { path = "/health"; port = 8080 }
            initial_delay_seconds = 10
            period_seconds = 10
          }
        }
      }
    }
  }
}
```

**Deployment features**:
- Resource limits and requests
- Liveness and readiness probes
- Rolling update strategy (default)
- Environment variables from ConfigMaps and Secrets

### Step 5: Create Service

```hcl
resource "kubernetes_service" "app" {
  metadata {
    name      = var.application_name
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = { app = var.application_name }
  }

  spec {
    type = "ClusterIP"
    selector = { app = var.application_name }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 8080
    }
  }
}
```

**Service types**:
- `ClusterIP` - Internal cluster access (default)
- `LoadBalancer` - External access via cloud LB
- `NodePort` - External access via NodeIP:Port
- `None` - Headless service for StatefulSets

### Step 6: Create Ingress

```hcl
resource "kubernetes_ingress" "app" {
  metadata {
    name      = var.application_name
    namespace = kubernetes_namespace.app.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    rule {
      host = var.ingress_host

      http {
        path {
          backend {
            service_name = kubernetes_service.app.metadata[0].name
            service_port = 80
          }
          path = "/"
        }
      }

      tls {
        hosts       = [var.ingress_host]
        secret_name = kubernetes_secret.tls_cert.metadata[0].name
      }
    }
  }
}
```

**Ingress requirements**:
- Ingress controller deployed (e.g., nginx-ingress)
- DNS record configured for host
- TLS certificate secret (cert-manager recommended)

### Step 7: Create Storage

```hcl
resource "kubernetes_storage_class" "gp2" {
  metadata { name = "gp2" }

  storage_provisioner = "kubernetes.io/aws-ebs"
  parameters = { type = "gp2" }

  allow_volume_expansion = true
  reclaim_policy = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_persistent_volume_claim" "data" {
  metadata {
    name      = "app-data"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class.gp2.metadata[0].name

    resources {
      requests = { storage = "10Gi" }
    }
  }
}
```

**Storage patterns**:
- `ReadWriteOnce` - Single node access
- `ReadWriteMany` - Multiple nodes (NFS)
- `ReadOnlyMany` - Multiple nodes read-only

### Step 8: Deploy Helm Chart

```hcl
resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = kubernetes_namespace.app.metadata[0].name

  set {
    name  = "auth.enabled"
    value = "true"
  }

  set {
    name  = "auth.password"
    value = var.redis_password
  }

  set {
    name  = "persistence.size"
    value = "8Gi"
  }
}
```

**Helm best practices**:
- Pin chart versions for reproducibility
- Use `set` blocks to override values
- Deploy in dedicated namespaces
- Use meaningful release names

### Step 9: Create Horizontal Pod Autoscaler

```hcl
resource "kubernetes_horizontal_pod_autoscaler" "app" {
  metadata {
    name      = "${var.application_name}-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind       = "Deployment"
      name       = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    target_cpu_utilization_percentage = 60
  }
}
```

**HPA requirements**:
- Resource requests configured (required)
- Metrics server deployed in cluster

### Step 10: Define Variables and Apply

Create `variables.tf`:

```hcl
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "app_namespace" {
  description = "Application namespace"
  type        = string
  default     = "app"
}

variable "application_name" {
  description = "Application name"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 3
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "ingress_host" {
  description = "Ingress host"
  type        = string
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

Apply changes:

```bash
export KUBECONFIG="/path/to/kubeconfig"

tofu init
tofu plan -out=tfplan
tofu apply tfplan

kubectl get all -n $APP_NAMESPACE
```

## Best Practices

### Resource Management

- Use namespaces for isolation
- Apply consistent labels to all resources
- Set resource requests and limits
- Configure liveness and readiness probes
- Use RollingUpdate for zero-downtime deployments

### Security

- Use RBAC to restrict permissions
- Store secrets in Kubernetes Secrets, not ConfigMaps
- Implement network policies for pod-to-pod communication
- Use signed and verified container images
- Define security contexts for pods and containers

### High Availability

- Deploy multiple replicas for critical applications
- Use pod anti-affinity to distribute across nodes
- Configure Pod Disruption Budgets
- Enable Horizontal Pod Autoscaler

### Storage

- Use appropriate storage classes for use case
- Use PVCs for stateful applications
- Enable storage expansion when possible
- Use StatefulSets for databases

## Common Issues

### Provider Connection Failed

**Symptom**: Error `Error: Failed to configure provider`

**Solution**:
```bash
kubectl cluster-info
kubectl config current-context
ls -la ~/.kube/config
```

### Image Pull Error

**Symptom**: Error `Failed to pull image`

**Solution**:
```bash
docker pull <image-name>
docker login <registry-url>

# Use image pull secrets
kubectl create secret docker-registry regcred \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password>
```

### Pod Pending State

**Symptom**: Pods stuck in Pending state

**Solution**:
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

Common issues:
- Insufficient resources (check requests/limits)
- Node affinity (check node selectors)
- Image pull errors

### Service Not Accessible

**Symptom**: Service is created but not accessible

**Solution**:
```bash
kubectl get endpoints <service-name>
kubectl get pods --show-labels
```

Check service type:
- `ClusterIP`: Only accessible within cluster
- `LoadBalancer`: External access via LB DNS
- `NodePort`: External access via NodeIP:Port

### Ingress Not Working

**Symptom**: Ingress created but traffic not reaching pods

**Solution**:
```bash
kubectl get pods -n ingress-nginx
kubectl describe ingress <ingress-name>
kubectl get secret <tls-secret-name>
nslookup <ingress-host>
```

### Persistent Volume Not Mounting

**Symptom**: Pod fails with volume mount errors

**Solution**:
```bash
kubectl get pvc
kubectl get sc
kubectl get pv
kubectl describe pod <pod-name> | grep -A 10 Events
```

### Autoscaling Not Working

**Symptom**: HPA not scaling pods

**Solution**:
```bash
kubectl get hpa
kubectl describe hpa <hpa-name>
kubectl describe pod <pod-name> | grep -A 5 Requests
kubectl top pods
```

Verify metrics server is running:
```bash
kubectl get pods -n kube-system | grep metrics
```

## References

- **Terraform Registry (Kubernetes Provider)**: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
- **Helm Provider**: https://registry.terraform.io/providers/hashicorp/helm/latest/docs
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Helm Documentation**: https://helm.sh/docs/
- **OpenTofu Documentation**: https://opentofu.org/docs/
