# Provider configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP Zone for zonal cluster"
  type        = string
  default     = "europe-west1-b"
}

variable "cluster_name" {
  description = "GKE Cluster Name"
  type        = string
  default     = "my-gke-cluster"
}

# GKE Zonal Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone  # Zone instead of region for zonal cluster

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Disable logging and monitoring
  logging_service    = "none"
  monitoring_service = "none"

  # Network configuration
  network    = "default"
  subnetwork = "default"

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.96.0.0/14"
    services_ipv4_cidr_block = "10.100.0.0/16"
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Master authorized networks (optional - allows access from anywhere)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }
}

# Main Node Pool (1 node, no auto-scaling)
resource "google_container_node_pool" "main_pool" {
  name       = "main-pool"
  location   = var.zone  # Zone instead of region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "n2d-standard-2"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      pool = "main-pool"
    }

    tags = ["gke-node", "main-pool"]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Application Node Pool (with auto-scaling, initial 2 nodes)
resource "google_container_node_pool" "application_pool" {
  name     = "application-pool"
  location = var.zone  # Zone instead of region
  cluster  = google_container_cluster.primary.name

  # Auto-scaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  initial_node_count = 1  

  node_config {
    preemptible  = false
    machine_type = "n2d-standard-2"

    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      pool = "application-pool"
    }

    tags = ["gke-node", "application-pool"]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
}

# IAM bindings for the service account
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Output values
output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = google_container_cluster.primary.location
}

output "main_pool_name" {
  description = "Main node pool name"
  value       = google_container_node_pool.main_pool.name
}

output "application_pool_name" {
  description = "Application node pool name"
  value       = google_container_node_pool.application_pool.name
}