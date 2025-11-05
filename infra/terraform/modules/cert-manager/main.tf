# ---------- Cert Manager ----------
locals {
  solver_config = [
    {
      http01 = {
        ingress = {
          class = var.ingress_class
        }
      }
    }
  ]

  cluster_issuers = {
    staging = {
      name        = var.cluster_issuer_staging_name
      secret_name = var.cluster_issuer_staging_private_key_secret_name
      server      = var.acme_server_staging
    }
    production = {
      name        = var.cluster_issuer_production_name
      secret_name = var.cluster_issuer_production_private_key_secret_name
      server      = var.acme_server_production
    }
  }
}

resource "kubernetes_namespace" "this" {
  metadata { name = var.namespace }
}

resource "helm_release" "this" {
  name       = var.release_name
  repository = var.chart_repository
  chart      = var.chart_name
  namespace  = kubernetes_namespace.this.metadata[0].name

  dynamic "set" {
    for_each = var.chart_set_values
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  depends_on = [kubernetes_namespace.this]
}

resource "kubernetes_manifest" "clusterissuer" {
  for_each = local.cluster_issuers

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = { name = each.value.name }
    spec = {
      acme = {
        email               = var.cluster_issuer_email
        server              = each.value.server
        privateKeySecretRef = { name = each.value.secret_name }
        solvers             = local.solver_config
      }
    }
  }

  depends_on = [helm_release.this]
}