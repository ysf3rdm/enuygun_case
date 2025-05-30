# Detailed Project Description

This project aims to set up a Kubernetes infrastructure on Google Cloud Platform (GCP) using the Infrastructure as Code (IaC) approach. The project includes GKE cluster setup, various node pools, sample application deployment, monitoring solutions (Prometheus & Grafana), auto-scaling (HPA & KEDA), and service mesh (Istio) installations.

## Project Structure

The project directory structure aims to improve readability and manageability by organizing different components into separate folders:

```
enuygun/
├── cluster/             # Terraform code for GKE cluster and node pools
│   ├── main.tf
│   └── terraform.tfvars
├── game-2048/         # Kubernetes manifests for the sample 2048 application
│   ├── 2048-deploymen-keda.yaml
│   └── 2048-service.yaml
├── istio/             # Terraform code for Istio service mesh installation
│   ├── istio-gateway.yaml   # Istio Gateway configuration (likely used here or elsewhere)
│   ├── istio.tf
│   └── terraform.tfvars
├── keda/              # Terraform code for KEDA installation
│   ├── keda.tf
│   └── terraform.tfvars
├── prometheus-stack/  # Terraform and Helm values for Prometheus and Grafana installation
│   ├── promethes-stack.tf
│   ├── terraform.tfvars
│   └── values.yaml
├── README.md          # Quick project overview and basic deployment steps
└── README_DETAILED.md # Detailed project description (this file)
```

## Technologies Used

The following main technologies are used in this project:

*   **Google Kubernetes Engine (GKE):** Used as the managed Kubernetes service.
*   **Terraform:** Used for provisioning infrastructure as code (IaC).
*   **Kubernetes:** Used for managing containerized applications.
*   **Helm:** Used for packaging and deploying Kubernetes applications.
*   **Horizontal Pod Autoscaler (HPA):** Automatically scales pods based on CPU utilization.
*   **KEDA (Kubernetes Event-driven Autoscaling):** Automatically scales workloads based on various event sources (Optional).
*   **Prometheus:** Open-source monitoring and alerting tool used for collecting Kubernetes metrics.
*   **Grafana:** Open-source analytics and monitoring platform used for visualizing Prometheus metrics and creating dashboards.
*   **Istio:** A configurable open-source service mesh layer for microservices (Optional).

## File Descriptions

Below are descriptions of the important files in the project:

*   `cluster/main.tf`: The main Terraform file defining the GKE cluster and the `main-pool` and `application-pool` node pools. Cluster settings (region, machine types, auto-scaling, etc.) are configured here.
*   `cluster/terraform.tfvars`: Contains the values for variables used in the `cluster/main.tf` file (GCP project ID, region, cluster name, etc.).
*   `game-2048/2048-deploymen-keda.yaml`: Kubernetes manifest file containing the Deployment definition for the sample 2048 application and the KEDA `ScaledObject` resource. It specifies which node pool the application will run on and the KEDA scaling rules.
*   `game-2048/2048-service.yaml`: Contains the Kubernetes Service definition used to expose the 2048 application.
*   `istio/istio.tf`: Terraform file used to install the Istio service mesh via Helm. Istio's core components (istiod, ingress/egress gateways) are configured here.
*   `istio/terraform.tfvars`: Contains the values for variables used in the `istio/istio.tf` file.
*   `keda/keda.tf`: Terraform file used to install KEDA via Helm.
*   `keda/terraform.tfvars`: Contains the values for variables used in the `keda/keda.tf` file.
*   `prometheus-stack/promethes-stack.tf`: Terraform file used to install Prometheus and Grafana via Helm. The `kube-prometheus-stack` Helm chart is used.
*   `prometheus-stack/terraform.tfvars`: Contains the values for variables used in the `prometheus-stack/promethes-stack.tf` file.
*   `prometheus-stack/values.yaml`: Contains configuration values for the Helm release in `prometheus-stack/promethes-stack.tf` (such as Grafana and Prometheus settings).

This detailed README file provides an additional resource for better understanding the project's content and components.

## Technical Details and Access

### Helm Usage

Helm charts have been used to deploy various components to Kubernetes in this project. Terraform manages these charts using the Helm provider:

*   **Prometheus Stack:** Prometheus and Grafana are installed using the `prometheus-community/kube-prometheus-stack` chart. Configuration is taken from the `prometheus-stack/values.yaml` file.
*   **Istio:** Different components of Istio are installed using Istio's own Helm charts. These include the `base`, `istiod`, and `gateway` charts. These charts are fetched from the `https://istio-release.storage.googleapis.com/charts` repository.
*   **KEDA:** KEDA is also likely installed using a Helm chart (file content was not retrieved, but this is the common method).

### Istio and LoadBalancer

As part of the Istio installation, the `istio-ingress` gateway is exposed as a Kubernetes `LoadBalancer` service (according to the configuration in `istio/istio.tf`). This automatically provisions a GCP LoadBalancer in the GCP environment. The external IP address of this LoadBalancer acts as a single entry point for accessing services (application, monitoring tools, etc.) from outside the cluster.

### Accessing Services

Access to services is provided through the Istio Ingress Gateway. First, you need to get the external IP address of the Istio Ingress Gateway service:

```shell
kubectl get svc -n istio-ingress istio-ingressgateway
```

Note the IP address in the `EXTERNAL-IP` column of the command output.

*   **2048 Application:** The 2048 application can be accessed via this external IP address. (If specific routing rules (`VirtualService`) are not defined on the Istio Gateway, it will either default to the application's Service port or depend on the Gateway configuration. The `istio-gateway.yaml` file can be used to define these routes).

*   **Prometheus and Grafana:** Prometheus and Grafana can also be accessed via the same Istio Ingress Gateway IP address. According to the settings in `prometheus-stack/values.yaml`, access to Grafana might be configured under the `/grafana/` path and Prometheus under the `/prometheus/` path. In this case, the access addresses might be:

    *   **Grafana:** `http://<Istio-Ingress-Gateway-EXTERNAL-IP>/grafana/login`
    *   **Prometheus:** `http://<Istio-Ingress-Gateway-EXTERNAL-IP>/prometheus/graph`

    (Access paths may vary depending on the Istio Gateway and/or Prometheus/Grafana Helm chart configuration, and additional Istio `VirtualService` or `Gateway` resources may be required).

The exact access addresses will depend on the Istio Gateway and the Service and Ingress/Gateway configurations of the applications/monitoring tools.