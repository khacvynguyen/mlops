output "namespace_name" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "release_name" {
  value = helm_release.this.name
}

output "cluster_issuer_names" {
  value = keys(kubernetes_manifest.clusterissuer)
}