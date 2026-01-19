variable "namespace" {
  type    = string
  default = "observability"
}

variable "image" {
  type = string
  default = "dannyanko/infra-traffic-gen:latest"
}

variable "replicas" {
  type    = number
  default = 1
}
