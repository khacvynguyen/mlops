# ---------- Backend ----------
locals {
  env_from_secret = [
    for item in var.env_list : {
      name  = item.name
      value = null
      secret_ref = {
        name = item.secret_name
        key  = item.secret_key
      }
    }
  ]

  env_from_plain = [
    for item in var.plain_env_list : {
      name       = item.name
      value      = item.value
      secret_ref = null
    }
  ]

  env_combined = concat(local.env_from_secret, local.env_from_plain)
}

resource "kubernetes_service" "this" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
  }

  spec {
    selector = var.selector_map
    port {
      port        = var.port
      target_port = var.target_port
    }
    type = "ClusterIP"
  }

  wait_for_load_balancer = false
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.deployment_name
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = var.selector_map
    }

    template {
      metadata {
        labels = var.selector_map
      }

      spec {
        container {
          name  = var.container_name
          image = var.image
          port { container_port = var.container_port }

          dynamic "env" {
            for_each = local.env_combined
            content {
              name  = env.value.name
              value = env.value.value

              dynamic "value_from" {
                for_each = env.value.secret_ref != null ? [env.value.secret_ref] : []
                content {
                  secret_key_ref {
                    name = value_from.value.name
                    key  = value_from.value.key
                  }
                }
              }
            }
          }
        }
        
        automount_service_account_token = false
        enable_service_links            = false
      }
    }
  }

  wait_for_rollout = false
}