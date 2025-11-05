output "frontend_ingress_name" {
  value = kubernetes_ingress_v1.frontend.metadata[0].name
}

output "oauth2_ingress_name" {
  value = kubernetes_ingress_v1.oauth2.metadata[0].name
}