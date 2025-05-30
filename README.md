# GCP Kubernetes Infrastructure Project

This project sets up a Kubernetes cluster on Google Cloud Platform (GCP) using Infrastructure as Code (IaC) with Terraform. The project includes the deployment of a 2048 game, monitoring tools, and advanced scaling and service mesh capabilities.

## Features:

- **Kubernetes Cluster on GKE:** A GKE cluster is provisioned in the `europe-west-1` region with logging and monitoring disabled.
- **Node Pools:** Two node pools (`main-pool` and `application-pool`) are created using `n2d` machine types. `main-pool` has auto-scaling disabled, while `application-pool` is configured to auto-scale between 1 and 3 nodes.
- **Sample Application Deployment:** A sample Kubernetes application is deployed specifically targeting the `application-pool`.
- **Horizontal Pod Autoscaler (HPA):** HPA is configured for the sample application to scale between 1 and 3 pods based on CPU usage exceeding 25%.
- **Prometheus and Grafana:** Prometheus and Grafana are installed on the cluster for collecting and visualizing Kubernetes metrics.
- **Grafana Alerting:** A pod restart alarm is configured in Grafana.
- **KEDA Integration (*Nice to Have*):** KEDA is installed and configured to provide alternative scaling based on external events.
- **Istio Service Mesh (*Nice to Have*):** Istio is installed, including `istiod`, `istio-ingress`, and `istio-egress` components.

## Technologies Used:

- Google Kubernetes Engine (GKE)
- Terraform (for IaC)
- Kubernetes YAML Manifests
- Horizontal Pod Autoscaler (HPA)
- Prometheus
- Grafana
- KEDA
- Istio
- Helm

This README provides a high-level overview of the project components and their configurations.

## Deployment

Follow these steps to deploy the infrastructure and application on GCP:

1.  **Set up GCP Credentials:** Ensure you have authenticated with GCP and set the correct project:

    ```shell
    gcloud auth login
    gcloud config set project <your-project-id>
    ```

2.  **Deploy the GKE Cluster:** Navigate to the `cluster` directory and apply the Terraform configuration:

    ```shell
    cd cluster
    terraform init
    terraform apply
    ```

3.  **Configure Kubectl:** Get the cluster credentials to configure `kubectl`:

    ```shell
    gcloud container clusters get-credentials <your-cluster-name> --region <your-region> --project <your-project-id>
    ```
    (Replace `<your-cluster-name>`, `<your-region>`, and `<your-project-id>` with your actual values or use the outputs from the cluster Terraform apply.)

4.  **Deploy Istio (Optional):** If you want to install the Istio service mesh, navigate to the `istio` directory and apply the Terraform configuration:

    ```shell
    cd ../istio
    terraform init
    terraform apply
    ```

5.  **Label Namespace for Istio Injection (if Istio deployed):** Label the namespace where your application will run (default is `default`) to enable Istio sidecar injection:

    ```shell
    kubectl label namespace default istio-injection=enabled
    ```

6.  **Label Monitoring Namespace for Istio Injection (if Istio deployed):** Label the `monitoring` namespace to enable Istio sidecar injection for the monitoring components:

    ```shell
    kubectl label namespace monitoring istio-injection=enabled
    ```

7.  **Deploy Prometheus and Grafana:** Navigate to the `prometheus-stack` directory and apply the Terraform configuration to deploy the monitoring stack using Helm:

    ```shell
    cd ../prometheus-stack
    terraform init
    terraform apply
    ```

8.  **Deploy the 2048 Application:** Apply the Kubernetes manifest for the game and KEDA ScaledObject:

    ```shell
    kubectl apply -f ../game-2048/2048-deploymen-keda.yaml
    kubectl apply -f ../game-2048/2048-service.yaml 
    ```

9.  **Deploy KEDA (Optional):** If you want to use KEDA for scaling (as defined in the application YAML), navigate to the `keda` directory and apply the Terraform configuration:

    ```shell
    cd ../keda
    terraform init
    terraform apply
    ```

Replace placeholders like `<your-project-id>`, `<your-region>`, and `<your-cluster-name>` with your specific configuration values.