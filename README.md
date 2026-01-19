## Infra Observability Lab: Platform Engineering and Incident Simulation

A comprehensive platform engineering lab demonstrating end-to-end automation: infrastructure provisioning with Terraform, CI/CD pipelines, GCP cloud services, Kubernetes deployments, observability with Prometheus and Grafana, and incident simulation for hands-on learning and experimentation.

---

### Project Overview

This lab provides a structured environment for building platform engineering skills. It emphasizes automation, integration, and observability in a reproducible way, covering infrastructure as code, CI/CD, cloud services, container orchestration, monitoring, and incident response.

---

#### Goals
- Demonstrate infrastructure provisioning with Terraform and GCP.
- Automate deployments and workflows via CI/CD pipelines.
- Integrate Kubernetes for containerized applications.
- Implement observability with Prometheus scraping and Grafana dashboards.
- Simulate incidents to practice detection, response, and resolution.

---

#### Architecture

The lab runs on Google Cloud Platform (GCP) with GKE Autopilot for Kubernetes. Terraform manages infrastructure, GitHub Actions handles CI/CD, and Prometheus/Grafana provide observability.

- **Infrastructure Layer**: GCP resources (GKE cluster, networking) provisioned via Terraform.
- **Application Layer**: demo-api (Flask app) and traffic-gen deployed to Kubernetes.
- **Observability Layer**: Prometheus scrapes metrics, Grafana visualizes data.
- **CI/CD Layer**: GitHub Actions automates builds, tests, and deployments.

![Architecture Diagram](architecture.png)

*A GCP-hosted GKE Autopilot cluster with Terraform-managed infrastructure, CI/CD automation, and observability tools.*

---

#### Key Components

| Component | Purpose |
|-----------|---------|
| `.github/workflows/` | GitHub Actions for CI/CD: builds, tests, image pushes, Terraform applies, incident simulations. |
| `demo_api/` | Python Flask application with versions (blue/green/red) for deployment demos. |
| `k8s/` | Kubernetes manifests for workloads, Prometheus, Grafana, using Kustomize for composition. |
| `terraform/` | Infrastructure as code for GCP provisioning. |
| `traffic_gen/` | Python script generating traffic to demo-api for observability testing. |
| `README.md` | Documentation and usage guide. |

---

### Prerequisites

#### Python Setup
Install dependencies:
```bash
pip install -r requirements.txt
```

#### Terraform Installation
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform -version
```

#### GCP Setup
```bash
brew install --cask google-cloud-sdk
gcloud auth login
gcloud config set project infra-observability-lab
gcloud services enable container.googleapis.com
```

#### Remote State
Create a GCS bucket for Terraform state:
```bash
gsutil mb -p infra-observability-lab -l us-central1 gs://infra-observability-tfstate/
```

Add to terraform/main.tf:
```hcl
terraform {
  backend "gcs" {
    bucket = "infra-observability-tfstate"
    prefix = "terraform/state"
  }
}
```

#### Service Account
Create a Terraform service account:
```bash
gcloud iam service-accounts create terraform \
  --display-name "Terraform Provisioner"
gcloud projects add-iam-policy-binding infra-observability-lab \
  --member="serviceAccount:terraform@infra-observability-lab.iam.gserviceaccount.com" \
  --role="roles/editor"
gcloud iam service-accounts keys create key.json \
  --iam-account=terraform@infra-observability-lab.iam.gserviceaccount.com
```

---

### Usage

#### Terraform Workflow
1. Initialize: `terraform init`
2. Plan: `terraform plan`
3. Apply: `terraform apply`

Connect to cluster:
```bash
gcloud container clusters get-credentials observability-lab --region us-central1
kubectl get nodes
```

#### CI/CD Pipelines
GitHub Actions automate the platform engineering workflow:
- **Triggers**: Pushes to main with path filters (e.g., `demo_api/**` for builds).
- **Builds**: Lint, test, build multi-arch Docker images, tag with SHA.
- **Deployments**: Push images, run Terraform apply.
- **Incident Simulation**: Manual workflows for traffic generation and service switching.

Example workflow (deploy-demo-api.yml):
- On push to demo_api/**: Build image, run tests, push to Docker Hub, apply Terraform with new image tag.

#### Incident Simulation
1. Trigger `demo-api-drills` workflow in "incident" mode: Scales red deployment to 1, traffic-gen to 5.
2. Observe: Errors in logs, restarts in k8s, alerts in Prometheus/Grafana.
3. Rollback: Run "rollback" mode to switch to green.

---

### Troubleshooting

#### Common Issues
- **Terraform State Lock**: Force unlock if stuck: `terraform force-unlock <ID>`
- **Image Pull Failures**: Check Docker Hub for tags; ensure workflows push correctly.
- **Rollout Timeouts**: Increase `progress_deadline_seconds` in deployments.
- **Memory Metrics Missing**: Ensure ProcessCollector in demo-api and cAdvisor in Prometheus.
- **WIF Errors**: Verify service account roles and audience.

#### Accessing Tools
- Prometheus: `kubectl port-forward svc/prometheus 9090:9090 -n observability`
- Grafana: `kubectl port-forward svc/grafana 3000:3000 -n observability` (admin/admin)

---

### Advanced Topics

#### Workload Identity Federation (WIF)
Authenticate GitHub Actions to GCP without keys:
1. Enable APIs: `gcloud services enable iam.googleapis.com sts.googleapis.com`
2. Create pool/provider: Follow GCP docs for OIDC setup.
3. Grant roles: `roles/iam.workloadIdentityUser` to service account.
4. Workflow config:
   ```yaml
   permissions:
     id-token: write
   - uses: google-github-actions/auth@v2
     with:
       workload_identity_provider: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
       service_account: terraform-sa@PROJECT_ID.iam.gserviceaccount.com
   ```

#### Kustomization
Use `kubectl apply -k k8s/` for declarative deployments with ConfigMaps and secrets.

#### Cloud Armor
Protect ingress with rate limiting:
1. Create policy: `gcloud compute security-policies create demo-api-policy`
2. Add rules for rate limits.
3. Attach via BackendConfig in Kubernetes.

---

### Incident Simulation Reporting

Document incidents:
- **Summary**: Impact, start/end times, trigger.
- **Detection**: Alerts, dashboards.
- **Response**: Actions taken.
- **Resolution**: How system recovered.
- **Lessons**: Improvements for observability.
