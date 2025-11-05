resource "kubernetes_namespace" "this" {
  metadata {
    name        = var.name
    labels      = var.labels
    annotations = var.annotations
  }
}