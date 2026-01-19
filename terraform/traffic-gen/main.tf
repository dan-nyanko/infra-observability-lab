resource "kubernetes_deployment_v1" "traffic_gen" {
  metadata {
    name      = "traffic-gen"
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas

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
          name  = "traffic-gen"
          image = var.image

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
