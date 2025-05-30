terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Configure Kubernetes and Helm providers
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


data "google_client_config" "default" {}

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Prometheus and Grafana installation using kube-prometheus-stack
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "55.0.0"
  values = [
    file("${path.module}/values.yaml")
  ]


  depends_on = [kubernetes_namespace.monitoring]
}

output "grafana_admin_password" {
  description = "Command to get Grafana admin password"
  value       = "kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
  sensitive   = true
}