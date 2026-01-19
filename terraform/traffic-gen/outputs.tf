output "traffic_gen_deployment_name" {
  value = kubernetes_deployment_v1.traffic_gen.metadata[0].name
}
