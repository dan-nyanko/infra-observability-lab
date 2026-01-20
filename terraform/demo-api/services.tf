# Shared Service for blue+green+red (for normal traffic)
resource "kubernetes_service_v1" "demo_api_shared" {
  metadata {
    name      = "demo-api"
    namespace = var.namespace

    # Conditionally add Cloud Armor BackendConfig annotation
    annotations = var.enable_cloud_armor_for_shared_service ? {
      "cloud.google.com/backend-config" = jsonencode({ default = var.shared_backendconfig_name })
    } : {}
  }

  spec {
    selector = {
      app = "demo-api"
      # Include all versions for load balancing
    }

    port {
      port        = var.service_port
      target_port = var.container_port
    }

    type = var.service_type
  }
}

# Isolated Service for red
resource "kubernetes_service_v1" "demo_api_red" {
  metadata {
    name      = "demo-api-red"
    namespace = var.namespace

    annotations = var.enable_cloud_armor_for_red_service ? {
      "cloud.google.com/backend-config" = jsonencode({ default = var.red_backendconfig_name })
    } : {}
  }

  spec {
    selector = {
      app     = "demo-api"
      version = "red"
    }

    port {
      port        = var.service_port
      target_port = var.container_port
    }

    type = var.service_type
  }
}
