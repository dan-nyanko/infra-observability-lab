variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE Autopilot cluster"
  type        = string
  default     = "observability-lab"
}

variable "resource_labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default = {
    environment = "development"
    purpose     = "observability-lab"
    managed-by  = "terraform"
  }
}