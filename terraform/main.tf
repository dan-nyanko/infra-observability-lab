terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "7.12.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

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

provider "kubernetes" {
  host  = "https://${google_container_cluster.autopilot.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  )
}

module "demo_api" {
  source               = "./demo-api"
  demo_api_image_blue  = var.demo_api_image_blue
  demo_api_image_green = var.demo_api_image_green
  demo_api_image_red   = var.demo_api_image_red
  replicas_red = var.replicas_red
}

module "traffic_gen" {
  source   = "./traffic-gen"
  traffic_gen_image    = var.traffic_gen_image
  replicas_traffic_gen = var.replicas_traffic_gen
}
