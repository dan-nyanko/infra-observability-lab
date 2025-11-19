provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "autopilot" {
  name     = var.cluster_name
  location = var.region

  enable_autopilot = true

  release_channel {
    channel = "REGULAR"
  }

  network    = "default"
  subnetwork = "default"

  resource_labels = var.resource_labels
}