# variables.tf
variable "namespace" {
  type        = string
  default     = "observability"
  description = "Target Kubernetes namespace"
}

variable "demo_api_image_blue" {
  type        = string
  description = "Image for demo-api blue version"
}

variable "demo_api_image_green" {
  type        = string
  description = "Image for demo-api green version"
}

variable "demo_api_image_red" {
  type        = string
  description = "Image for demo-api red version"
}

variable "replicas_blue" {
  type    = number
  default = 1
}

variable "replicas_green" {
  type    = number
  default = 1
}

variable "replicas_red" {
  type    = number
  default = 0 # red off by default
}

variable "enable_cloud_armor_for_shared_service" {
  type        = bool
  default     = true
  description = "Attach BackendConfig to the shared blue/green Service"
}

variable "shared_backendconfig_name" {
  type        = string
  default     = "demo-api-backendconfig"
  description = "BackendConfig name for the shared Service (blue+green)"
}

variable "enable_cloud_armor_for_red_service" {
  type        = bool
  default     = true
  description = "Attach BackendConfig to the red-only Service (drills often bypass)"
}

variable "red_backendconfig_name" {
  type        = string
  default     = "demo-api-backendconfig"
  description = "BackendConfig name for the red Service if enabled"
}

variable "service_type" {
  type        = string
  default     = "NodePort"
  description = "Service type (NodePort to integrate with GKE Ingress/HTTP LB)"
}

variable "service_port" {
  type    = number
  default = 80
}

variable "container_port" {
  type    = number
  default = 5000
}
