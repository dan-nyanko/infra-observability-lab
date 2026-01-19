variable "namespace" {
  type    = string
  default = "observability"
}

variable "image" {
  type = string
}

variable "replicas" {
  type    = number
  default = 1
}
