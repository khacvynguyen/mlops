resource "kubernetes_secret" "this" {
  metadata {
    name        = var.name
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  type        = var.type
  data        = var.data
}