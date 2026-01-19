variable "namespace" {
  type    = string
  default = "observability"
}

variable "traffic_gen_image" {
  type = string
  default = "dannyanko/infra-traffic-gen:latest"
}

variable "replicas_traffic_gen" {
  type    = number
  default = 1
}
