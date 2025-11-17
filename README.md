## Infra Observability Lab

A hands-on DevOps lab exploring infrastructure provisioning, observability tooling, incident simulation, and CI/CD workflows—built on GCP for learning and experimentation.

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

### Setup Instructions

#### 1. Clone the repo

```bash
git clone git@github.com:your-username/infra-observability-lab.git
cd infra-observability-lab
```

#### 2. Provision GKE Autopilot (Terraform)

```bash
cd terraform
terraform init
terraform apply
```

> Requires GCP credentials and billing enabled. Uses free-tier eligible resources.

#### 3. Deploy Prometheus + Grafana

```bash
kubectl apply -f monitoring/prometheus.yml
kubectl apply -f monitoring/grafana-dashboard.json
```

#### 4. Run Incident Simulation

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

### Roadmap

- [ ] Add Cloud Run variant for exporter services
- [ ] Integrate Alertmanager with Slack or email
- [ ] Simulate network latency and pod eviction
- [ ] Add chaos engineering module
- [ ] Create AWS variant for cross-cloud orchestration

---

### References

- [GoogleCloudPlatform/platform-engineering](https://github.com/GoogleCloudPlatform/platform-engineering)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
