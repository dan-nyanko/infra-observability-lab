terraform {
  backend "gcs" {
    bucket  = "infra-observability-tfstate"
    prefix  = "terraform/state"
  }
}