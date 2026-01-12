# Blue Deployment
resource "kubernetes_deployment_v1" "demo_api_blue" {
  metadata {
    name      = "demo-api-blue"
    namespace = var.namespace
    labels = {
      app     = "demo-api"
      version = "blue"
    }
  }

  spec {
    replicas = var.replicas_blue

    selector {
      match_labels = {
        app     = "demo-api"
        version = "blue"
      }
    }

    template {
      metadata {
        labels = {
          app     = "demo-api"
          version = "blue"
          environment = "development"
        }
      }
      spec {
        container {
          name  = "demo-api"
          image = var.demo_api_image_blue

          port {
            name           = "metrics"
            container_port = var.container_port
          }

          env {
            name  = "VERSION"
            value = "blue"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "400m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/readyz"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# Green Deployment
resource "kubernetes_deployment_v1" "demo_api_green" {
  metadata {
    name      = "demo-api-green"
    namespace = var.namespace
    labels = {
      app     = "demo-api"
      version = "green"
      environment = "development"
    }
  }

  spec {
    replicas = var.replicas_green

    selector {
      match_labels = {
        app     = "demo-api"
        version = "green"
      }
    }

    template {
      metadata {
        labels = {
          app     = "demo-api"
          version = "green"
          environment = "development"
        }
      }
      spec {
        container {
          name  = "demo-api"
          image = var.demo_api_image_green

          port {
            name           = "metrics"
            container_port = var.container_port
          }

          env {
            name  = "VERSION"
            value = "green"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "400m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/readyz"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# Red Deployment (drill)
resource "kubernetes_deployment_v1" "demo_api_red" {
  metadata {
    name      = "demo-api-red"
    namespace = var.namespace
    labels = {
      app     = "demo-api"
      version = "red"
    }
  }

  spec {
    replicas = var.replicas_red

    selector {
      match_labels = {
        app     = "demo-api"
        version = "red"
      }
    }

    template {
      metadata {
        labels = {
          app     = "demo-api"
          version = "red"
          environment = "development"
        }
      }
      spec {
        container {
          name  = "demo-api"
          image = var.demo_api_image_red

          port {
            name           = "metrics"
            container_port = var.container_port
          }

          env {
            name  = "VERSION"
            value = "red"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "400m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/readyz"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}
