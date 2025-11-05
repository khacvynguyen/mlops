output "name" {
  value = kubernetes_secret.this.metadata[0].name
}

output "namespace" {
  value = kubernetes_secret.this.metadata[0].namespace
}