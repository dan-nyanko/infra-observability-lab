############################################################
# auth-wif-github.tf
# Workload Identity Federation setup for GitHub Actions → GCP
############################################################

# Enable IAM API
resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "OIDC pool for GitHub Actions"
}

# Workload Identity Provider (GitHub OIDC)
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  description                        = "Trust GitHub OIDC tokens"

  oidc {
    issuer_uri        = "https://token.actions.githubusercontent.com"
    allowed_audiences = ["https://github.com/"]
  }

  # Map claims from GitHub’s OIDC token
  attribute_mapping = {
    "google.subject"        = "assertion.sub"
    "attribute.repository"  = "assertion.repository"
    "attribute.ref"         = "assertion.ref"
    "attribute.actor"       = "assertion.actor"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  # 👇 Explicit condition referencing mapped claims
  attribute_condition = "attribute.repository == 'dan-nyanko/infra-observability-lab' && attribute.ref == 'refs/heads/main'"
}

# Service Account for Terraform
resource "google_service_account" "terraform_sa" {
  project      = var.project_id
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}

# Allow GitHub repo (main branch) to impersonate the service account
resource "google_service_account_iam_binding" "terraform_sa_binding" {
  service_account_id = google_service_account.terraform_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-pool/attribute.repository/dan-nyanko/infra-observability-lab"
  ]
}
