# ---------- Ingress ----------
resource "kubernetes_ingress_v1" "frontend" {
  metadata {
    name      = "llm-app-ingress"
    namespace = var.namespace
    annotations = merge({
      "nginx.ingress.kubernetes.io/auth-url"        = var.auth_url
      "nginx.ingress.kubernetes.io/auth-signin"     = var.auth_signin
      "cert-manager.io/cluster-issuer"              = var.cluster_issuer
      "nginx.ingress.kubernetes.io/proxy-body-size" = "10m"
    }, var.frontend_annotations)
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.host]
      secret_name = var.tls_secret_name
    }

    rule {
      host = var.host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = var.frontend_service_name
              port { number = var.frontend_service_port }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "oauth2" {
  metadata {
    name      = "oauth2-proxy-ingress"
    namespace = var.namespace
    annotations = merge({
      "cert-manager.io/cluster-issuer" = var.cluster_issuer
    }, var.oauth2_annotations)
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.host]
      secret_name = var.tls_secret_name
    }

    rule {
      host = var.host

      http {
        path {
          path      = "/oauth2"
          path_type = "Prefix"

          backend {
            service {
              name = var.oauth2_service_name
              port { number = var.oauth2_service_port }
            }
          }
        }
      }
    }
  }
}