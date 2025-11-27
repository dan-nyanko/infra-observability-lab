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

| Module                | Purpose                                                                 |
|-----------------------|-------------------------------------------------------------------------|
| `terraform/`          | Infrastructure-as-code to provision the GKE Autopilot cluster and base networking |
| `k8s/`                | Kubernetes manifests for workloads and observability stack (Prometheus, Grafana, infra-demo-api) |
| `incidents/`          | Simulation scripts (Bash/Python) to trigger stress scenarios: CPU spikes, memory leaks, disk fill |
| `.github/workflows/`  | GitHub Actions pipelines for linting, testing, image build/push, and cluster deploy |
| `dashboards/`         | Grafana dashboard JSON templates for visualizing metrics and incident impact |
| `architecture.png`    | System diagram showing cluster flow, observability, and CI/CD integration |
| `README.md`           | Entry point documentation, reliability framing, and demo instructions |

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

### 📦 infra-demo-api

`infra-demo-api` is a lightweight demo service used to illustrate blue/green deployments, observability, and incident simulation. It exposes a simple HTTP endpoint that responds with a version string, making it easy to visualize traffic shifts in Prometheus and Grafana.

#### 🔍 Features
- Minimal Flask/Express-style API returning `Hello from demo-api <VERSION>!`
- Configurable via environment variable `VERSION` (e.g., `v1`, `v2`)
- Exposes `/metrics` endpoint for Prometheus scraping
- Designed for teaching reproducible Kubernetes workflows

#### 🚀 Usage (Docker)
You don’t need to build the image yourself — just pull from Docker Hub:

```bash
docker run -p 5000:5000 \
  -e VERSION=v1 \
  dannyanko/infra-demo-api:latest
```

Visit [http://localhost:5000](http://localhost:5000) → returns:
```
Hello from demo-api v1!
```

#### 📄 Kubernetes Deployment
Reference the public image in your manifests:

```yaml
containers:
- name: infra-demo-api
  image: dannyanko/infra-demo-api:latest
  ports:
  - containerPort: 5000
  env:
  - name: VERSION
    value: "blue"   # or "green"
```

#### 🧭 Best Practices
- **Never rely on `:latest`** in production. It’s mutable and prone to caching issues.
- **Always use versioned tags** (`:v1`, `:v2`, etc.) for reproducibility.
- Document image versions in your repo so learners know which tag to deploy.
- CI/CD pipelines should automatically bump tags and roll out new versions.

---

### Prometheus

Here’s a safe **Prometheus ConfigMap template** that matches the same `envsubst` style we used for Grafana secrets. This way, you can keep scrape targets flexible and reproducible without hard‑coding cluster service names:

---

#### 📄 `k8s/prometheus/prometheus-config.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: observability
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'infra-demo-api'
        static_configs:
          - targets: ["${PROMETHEUS_TARGET}"]
```
---

Prometheus requires scrape targets to be defined. To keep the repo safe and flexible, we use a template ConfigMap (`prometheus-config.yaml`) with an environment variable placeholder.

1. Export your target service:
   ```bash
   export PROMETHEUS_TARGET=infra-demo-api.observability.svc.cluster.local:80
   ```

2. Apply the config using `envsubst`:
   ```bash
   envsubst < k8s/prometheus/prometheus-config.yaml | kubectl apply -f -
   ```

3. Deploy Prometheus:
   ```bash
   kubectl apply -f k8s/prometheus/prometheus-deployment.yaml
   kubectl apply -f k8s/prometheus/prometheus-service.yaml
   ```

Prometheus will now scrape metrics from the `infra-demo-api` service.

### Grafana

#### 📄 `k8s/grafana/grafana-secret.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin-secret
  namespace: observability
type: Opaque
stringData:
  GF_SECURITY_ADMIN_PASSWORD: "${GRAFANA_PASSWORD}"
```

- Note: `${GRAFANA_PASSWORD}` is a placeholder.  
- You’ll set the environment variable in your shell before applying.

#### 🔐 Grafana Admin Password

Grafana requires an admin password. For security, we don’t commit real secrets into Git.
Instead, we use a template Secret manifest (`grafana-secret.yaml`) with a placeholder.

1. Export your password as an environment variable:
   ```bash
   export GRAFANA_PASSWORD=supersecure
   ```

2. Apply the secret using `envsubst`:
   ```bash
   envsubst < k8s/grafana/grafana-secret.yaml | kubectl apply -f -
   ```

3. Deploy Grafana:
   ```bash
   kubectl apply -f k8s/grafana/grafana-deployment.yaml
   kubectl apply -f k8s/grafana/grafana-service.yaml
   ```

4. Log in:
   - URL: `http://<EXTERNAL-IP>:3000`
   - User: `admin`
   - Password: the value you set in `$GRAFANA_PASSWORD`

---

#### 🧭 Why this is best practice
- **No secrets in Git** → you only commit a template.  
- **Reproducible** → anyone cloning the repo can follow the same workflow.  
- **Flexible** → rotate passwords by re‑exporting `GRAFANA_PASSWORD` and re‑applying the Secret.  

---

Here’s a polished **README section** you can drop straight into your repo to guide learners through debugging Kubernetes secrets. It’s written in a reproducible, teaching‑artifact style that matches the rest of your observability lab:

---

## 🔐 Debugging Kubernetes Secrets

Secrets are critical for storing credentials (like Grafana’s admin password). If they’re mis‑applied or left empty, pods may fail to start correctly or you won’t be able to log in. Here’s how to debug and fix them.

### 1. Inspect the Secret
Check if the secret exists and what keys it contains:
```bash
kubectl get secret grafana-admin-secret -n observability
kubectl describe secret grafana-admin-secret -n observability
```

Decode a specific key:
```bash
kubectl get secret grafana-admin-secret -n observability \
  -o jsonpath="{.data.GF_SECURITY_ADMIN_PASSWORD}" | base64 --decode
```

- If you see nothing or `${PLACEHOLDER}`, the secret wasn’t populated correctly.
- If you see your expected password, the secret is valid.

---

### 2. Common Issues
- **Empty values (0 bytes):** Usually caused by skipping `envsubst` when applying manifests with placeholders.
- **Wrong key names:** Grafana expects `GF_SECURITY_ADMIN_PASSWORD`.
- **Pod not restarted:** Even after fixing the secret, the Grafana pod may still be using the old value.

---

### 3. Fixing a Broken Secret
Delete the bad secret:
```bash
kubectl delete secret grafana-admin-secret -n observability
```

Re‑create with real value:
```bash
kubectl create secret generic grafana-admin-secret \
  --from-literal=GF_SECURITY_ADMIN_PASSWORD=changeme \
  -n observability
```

Verify you have a value:
```bash
kubectl describe secret grafana-admin-secret -n observability
```

Restart Grafana pod so it picks up the new secret:
```bash
kubectl delete pod -l app=grafana -n observability
```

---

### 4. Best Practices
- Always run manifests with placeholders through `envsubst`:
  ```bash
  export GRAFANA_PASSWORD=changeme
  envsubst < k8s/grafana/grafana-secret.yaml | kubectl apply -f -
  ```
- Document expected secret keys in your repo.
- Verify secrets before trying to log in.

---

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
