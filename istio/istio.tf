# Istio Installation with Terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

# Get cluster info
data "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
}

# Get access token
data "google_client_config" "default" {}

# Variables
variable "cluster_name" {
  description = "GKE Cluster Name"
  type        = string
  default     = "my-gke-cluster"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west1"
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "airy-advantage-461315-e1"
}

# Create istio-system namespace
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      "istio-injection" = "disabled"
    }
  }
}

# Install Istio Base (CRDs and cluster roles)
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.20.1"

  create_namespace = false
  
  set {
    name  = "defaultRevision"
    value = "default"
  }

  depends_on = [kubernetes_namespace.istio_system]
}

# Install Istiod (Control Plane)
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.20.1"

  create_namespace = false

  set {
    name  = "telemetry.v2.enabled"
    value = "true"
  }

  set {
    name  = "global.meshID"
    value = "mesh1"
  }

  set {
    name  = "global.multiCluster.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "global.network"
    value = "network1"
  }

  depends_on = [helm_release.istio_base]

  timeout = 600
}

# Create istio-ingress namespace
resource "kubernetes_namespace" "istio_ingress" {
  metadata {
    name = "istio-ingress"
    labels = {
      "istio-injection" = "enabled"
    }
  }
  depends_on = [helm_release.istiod]
}

# Install Istio Ingress Gateway
resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_ingress.metadata[0].name
  version    = "1.20.1"

  create_namespace = false

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "service.ports[0].port"
    value = "15021"
  }

  set {
    name  = "service.ports[0].name"
    value = "status-port"
  }

  set {
    name  = "service.ports[1].port"
    value = "80"
  }

  set {
    name  = "service.ports[1].name"
    value = "http2"
  }

  set {
    name  = "service.ports[2].port"
    value = "443"
  }

  set {
    name  = "service.ports[2].name"
    value = "https"
  }

  depends_on = [kubernetes_namespace.istio_ingress]

  timeout = 600
}

# Create istio-egress namespace
resource "kubernetes_namespace" "istio_egress" {
  metadata {
    name = "istio-egress"
    labels = {
      "istio-injection" = "enabled"
    }
  }
  depends_on = [helm_release.istiod]
}

# Install Istio Egress Gateway
resource "helm_release" "istio_egress" {
  name       = "istio-egress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_egress.metadata[0].name
  version    = "1.20.1"

  create_namespace = false

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "service.ports[0].port"
    value = "80"
  }

  set {
    name  = "service.ports[0].name"
    value = "http2"
  }

  set {
    name  = "service.ports[1].port"
    value = "443"
  }

  set {
    name  = "service.ports[1].name"
    value = "https"
  }

  # Egress gateway specific configuration
  set {
    name  = "labels.app"
    value = "istio-egressgateway"
  }

  set {
    name  = "labels.istio"
    value = "egressgateway"
  }

  depends_on = [kubernetes_namespace.istio_egress]

  timeout = 600
}

# Outputs
output "istio_ingress_ip" {
  description = "Istio Ingress Gateway External IP"
  value       = "Run: kubectl get svc -n istio-ingress"
}

output "istio_status" {
  description = "Check Istio installation status"
  value       = "Run: kubectl get pods -n istio-system"
}

output "istio_version" {
  description = "Installed Istio version"
  value       = "1.20.1"
}