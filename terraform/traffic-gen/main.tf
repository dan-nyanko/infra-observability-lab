resource "kubernetes_deployment_v1" "traffic_gen" {
  metadata {
    name      = "traffic-gen"
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas_traffic_gen

    selector {
      match_labels = {
        app = "traffic-gen"
      }
    }

    template {
      metadata {
        labels = {
          app = "traffic-gen"
        }
      }

      spec {
        container {
          name = "traffic-gen"
          image = var.traffic_gen_image
          image_pull_policy = "Always"

          env {
            name  = "SERVICE_URL"
            value = "http://demo-api.observability.svc.cluster.local"
          }

          env {
            name  = "INTERVAL"
            value = "1.0"
          }
        }
      }
    }
  }
}
