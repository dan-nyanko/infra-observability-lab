variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_number" {
  type        = string
  description = "The numeric GCP project number"
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

variable "demo_api_image_blue" {
  type    = string
  default = "dannyanko/infra-demo-api:latest"
}

variable "demo_api_image_green" {
  type    = string
  default = "dannyanko/infra-demo-api:latest"
}

variable "demo_api_image_red" {
  type    = string
  default = "dannyanko/infra-demo-api:latest"
}

variable "replicas_red" {
  type    = number
  default = 0
}

variable "replicas_traffic_gen" {
  type    = number
  default = 1
}

variable "traffic_gen_image" {
  type    = string
  default = "dannyanko/infra-traffic-gen:latest"
}

variable "traffic_gen_replicas" {
  type    = number
  default = 1
}
