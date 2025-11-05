output "name" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "uid" {
  value = kubernetes_namespace.this.metadata[0].uid
}