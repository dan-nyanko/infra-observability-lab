## Infra Observability Lab

A hands-on DevOps lab exploring infrastructure provisioning, observability tooling, incident simulation, and CI/CD workflows — built on GCP for learning and experimentation.

---

### Project Overview

This lab demonstrates key platform engineering principles using Google Cloud Platform (GCP), Terraform, Prometheus, Grafana, and GitHub Actions. It’s designed as a sandbox for exploring:

- Infrastructure-as-code provisioning
- Observability-first system design
- Incident simulation and recovery workflows
- CI/CD hygiene and automation

---

### Architecture

![Architecture Diagram](architecture.png)  
*A GCP-hosted GKE Autopilot cluster runs Prometheus and Grafana. Metrics are collected from simulated workloads and exposed via exporters. Alerts trigger based on thresholds, and incident simulations validate recovery paths.*

---

### 🔧 Components

| Module | Description |
|--------|-------------|
| `terraform/` | Provisions GKE Autopilot cluster and supporting resources |
| `monitoring/` | Prometheus config, Grafana dashboard, alerting rules |
| `incidents/` | Bash/Python scripts to simulate CPU spikes, disk fill, etc. |
| `.github/workflows/` | CI/CD pipeline with linting, testing, and deploy stages |
| `architecture.png` | Visual diagram of system flow |
| `README.md` | Documentation and reliability framing |

---

### Environment Strategy

In production-grade GCP environments, it’s a best practice to use separate projects for each environment (e.g., development, staging, production). This enables:

•  Clear isolation of resources and IAM policies
•  Environment-specific billing and quotas
•  Safer CI/CD pipelines and policy enforcement

#### Lab Context

For this lab, all resources are provisioned into a single GCP project to simplify setup and reduce cost. To simulate environment separation, we apply consistent [GCP resource labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels) labels applied via Terraform.

> When scaling this lab into a production-like setup, consider using one GCP project per environment and managing shared configuration via Terraform workspaces, modules, or a multi-project structure.

#### Example label schema:

| Key           | Value               | Purpose                                  |
|---------------|---------------------|------------------------------------------|
| `environment` | `development`       | Signals lifecycle stage                  |
| `purpose`     | `observability-lab` | Context for dashboards and billing       |
| `managed-by`  | `terraform`         | Shows infra-as-code ownership            |

These labels are defined in `variables.tf` and applied to all supported resources via the `resource_labels` map.

#### Example usage in Terraform:

```hcl
resource "google_container_cluster" "autopilot" {
  name     = var.cluster_name
  location = var.region
  enable_autopilot = true

  ...

  resource_labels = var.resource_labels
}
```

---

### Prerequisites

#### Install Terraform (macOS)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Verify installation:

```bash
terraform -version
```

> For other platforms, see [Terraform Downloads](https://developer.hashicorp.com/terraform/downloads)

#### Install gcloud CLI

```bash
brew install --cask google-cloud-sdk
```

Authenticate and set your project:

```bash
gcloud auth login
gcloud config set project your-project-id
gcloud services enable container.googleapis.com
```

#### Remote State with GCS

To enable shared, auditable infrastructure state, this lab uses Terraform remote state stored in a GCS bucket.

```bash
gsutil mb -p YOUR_PROJECT_ID -l us-central1 gs://infra-observability-tfstate/
```

Then add backend.tf in the terraform/ directory:

```Hcl
terraform {
  backend "gcs" {
    bucket  = "infra-observability-tfstate"
    prefix  = "terraform/state"
  }
}
```

#### Service Account for Terraform

To isolate provisioning from personal credentials and prepare for CI/CD, create a dedicated service account:

```bash
gcloud iam service-accounts create terraform \
  --display-name "Terraform Provisioner"

gcloud projects add-iam-policy-binding infra-observability-lab \
  --member="serviceAccount:terraform@infra-observability-lab.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud iam service-accounts keys create key.json \
  --iam-account=terraform@infra-observability-lab.iam.gserviceaccount.com
```

> Move `key.json` outside the repository, such as `~/.gcp/`, so it is not commited


#### Setting up `GCP_TF_KEY` for GitHub Actions

To allow Terraform to authenticate with Google Cloud during CI/CD runs, you’ll need to provide a service account key as a GitHub secret.

1. Create a Service Account in GCP

•  Go to IAM & Admin → Service Accounts in the GCP Console.
•  Create a new service account (e.g., terraform-ci).
•  Assign it the necessary roles (e.g., roles/editor or more restricted roles like roles/storage.admin depending on your use case).
•  Generate a JSON key and download it.

2. Add the Key to GitHub Secrets

•  Open your GitHub repo → Settings → Secrets and variables → Actions → New repository secret.
•  Name the secret: GCP_TF_KEY.
•  Paste the entire JSON key file contents into the value field.  

> On macOS you can copy the file contents with pbcopy < ~/.gcp/key.json and paste directly.

---

### Usage: Terraform Workflow

This lab provisions infrastructure on Google Cloud using Terraform. The typical workflow is:

#### 1. Initialize Terraform
Run once per new environment or after adding providers/modules:

```bash
terraform init
```

- Downloads the required provider plugins (e.g., `google`).  
- Sets up the backend for state storage.  
- Prepares the working directory for use.

---

#### 2. Preview Changes (Plan)
Generate an execution plan to see what Terraform will do:

```bash
terraform plan
```

- Shows resources to be created, updated, or destroyed.  
- Safe to run multiple times.  
- Use this step in CI/CD workflows for review before apply.

---

#### 3. Apply Changes
Provision the resources in GCP:

```bash
terraform apply
```

- Executes the plan and creates the infrastructure.  
- Prompts for confirmation unless `-auto-approve` is used.  
- Example: creates the GKE cluster defined in your configuration.

---

#### 4. Connect to the Cluster
Once the cluster is provisioned, configure `kubectl` to talk to it:

```bash
gcloud container clusters get-credentials observability-lab --region us-central1
```

- Updates your local `~/.kube/config` with cluster credentials.  
- Sets the current context to the new cluster.  

Verify connectivity:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

#### Workflow Hygiene
- Always run `plan` before `apply` to review changes.  
- Use GitHub Actions workflows to automate `plan` (PR) and `apply` (merge).  
- Document incidents and recovery steps in the README for reproducibility.

---

### Post‑Apply Cluster Setup

After provisioning the GKE cluster with Terraform, you may see warnings in the Cloud Console:

#### ⚠️ Verify Webhook Endpoints
- **Meaning**: Admission webhooks (used for policy enforcement or mutating workloads) must be reachable and healthy.  
- **Action**:  
  - If you haven’t deployed custom webhooks, you can ignore this for now.  
  - If you add webhooks later, confirm they’re accessible from the cluster and don’t block pod scheduling (`kubectl describe pod` will show webhook errors).


#### ⚠️ Set Maintenance Window
- **Meaning**: GKE automatically upgrades control plane and nodes. By default, upgrades can occur at any time.  
- **Action**:  
  - In the Cloud Console, go to **Cluster details → Maintenance window**.  
  - Set a preferred time (e.g., 2–4 AM local) when upgrades are least disruptive.  
  - This is optional in a lab, but demonstrates proactive ops hygiene.

---

#### ⚠️ Common Setup Errors
- **403: Kubernetes Engine API not enabled**  
  Enable it before running `apply`:
  ```bash
  gcloud services enable container.googleapis.com
  ```
- **Pods stuck in `Pending`**  
  - Cluster may still be initializing — wait a few minutes.  
  - Check pod events with `kubectl describe pod <name>`.  
  - Ensure resource requests/limits are compatible with Autopilot.

---

### Prometheus

TODO

```bash
kubectl apply -f monitoring/prometheus.yml
```

### Grafana

TODO

```bash
kubectl apply -f monitoring/grafana-dashboard.json
```

### Run Incident Simulation

```bash
bash incidents/simulate_cpu_spike.sh
```

> Observe alerts in Grafana and document recovery steps using `postmortem-template.md`.

---

### Reliability Principles

This lab reinforces:
- **Observability-first design**: Metrics, dashboards, and alerting from day one
- **Infrastructure as code**: Declarative provisioning with Terraform
- **Incident culture**: Simulations, postmortems, and recovery workflows
- **CI/CD hygiene**: Automated linting, testing, and deploys via GitHub Actions

---

### References

- [GoogleCloudPlatform/platform-engineering](https://github.com/GoogleCloudPlatform/platform-engineering)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
