module "namespace_ingress" {
  source = "./modules/namespace"
  name   = "ingress-nginx"
}

module "namespace_llm_app" {
  source = "./modules/namespace"
  name   = "llm-app"
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.13.3"
  namespace  = module.namespace_ingress.name
}

# ---------- Backend ----------
module "llm_backend" {
  source = "./modules/backend"

  namespace       = module.namespace_llm_app.name
  service_name    = "llm-backend-service"
  deployment_name = "llm-backend"
  container_name  = "llm-backend"
  image           = var.backend_image
  replicas        = var.backend_replicas
  selector_map    = { app = "llm-backend" }
  port            = 80
  target_port     = 8080
  container_port  = 8080

  env_list = [
    {
      name        = "GEMINI_API_KEY"
      secret_name = module.secret_gemini.name
      secret_key  = "GEMINI_API_KEY"
    },
    {
      name        = "LANGFUSE_PUBLIC_KEY"
      secret_name = module.secret_langfuse.name
      secret_key  = "LANGFUSE_PUBLIC_KEY"
    },
    {
      name        = "LANGFUSE_SECRET_KEY"
      secret_name = module.secret_langfuse.name
      secret_key  = "LANGFUSE_SECRET_KEY"
    }
  ]

  plain_env_list = []
}

# ---------- Frontend ----------
module "llm_frontend" {
  source = "./modules/frontend"

  namespace       = module.namespace_llm_app.name
  service_name    = "llm-frontend-service"
  deployment_name = "llm-frontend"
  container_name  = "llm-frontend"
  image           = var.frontend_image
  replicas        = var.frontend_replicas
  selector_map    = { app = "llm-frontend" }
  port            = 80
  target_port     = 8080
  container_port  = 8080
  env_list        = []

  plain_env_list = [
    {
      name  = "BACKEND_URL"
      value = "http://llm-backend-service.llm-app.svc.cluster.local/inference"
    },
    {
      name  = "OAUTH_REDIRECT_URL"
      value = "https://mlops-ai.duckdns.org/oauth2/callback"
    },
    {
      name  = "STREAMLIT_SERVER_ENABLE_CORS"
      value = "false"
    },
    {
      name  = "STREAMLIT_SERVER_ENABLE_XSRF_PROTECTION"
      value = "false"
    },
    {
      name  = "STREAMLIT_LOG_LEVEL"
      value = "debug"
    },
    {
      name  = "STREAMLIT_SERVER_ENABLE_WEBSOCKET_COMPRESSION"
      value = "true"
    }
  ]
}

# ---------- oauth2-proxy ----------
module "oauth2_proxy" {
  source = "./modules/oauth2"

  namespace       = module.namespace_llm_app.name
  service_name    = "oauth2-proxy-service"
  deployment_name = "oauth2-proxy"
  container_name  = "oauth2-proxy"
  image           = "quay.io/oauth2-proxy/oauth2-proxy:v7.6.0"
  replicas        = var.oauth2_replicas
  selector_map    = { app = "oauth2-proxy" }
  port            = 80
  target_port     = 4180
  container_port  = 4180
  args = [
    "--provider=google",
    "--http-address=0.0.0.0:4180",
    "--upstream=http://llm-frontend-service.llm-app.svc.cluster.local:80",
    "--authenticated-emails-file=/config/email_whitelist.txt",
    "--email-domain=*",
    "--redirect-url=https://mlops-ai.duckdns.org/oauth2/callback",
    "--cookie-domain=mlops-ai.duckdns.org",
    "--whitelist-domain=.mlops-ai.duckdns.org",
    "--cookie-secure=true",
    "--cookie-refresh=1h",
    "--cookie-expire=8h",
    "--set-authorization-header=true",
    "--skip-provider-button=true",
    "--skip-auth-strip-headers=true",
    "--proxy-prefix=/oauth2",
    "--skip-auth-regex=^/_stcore/.*"
  ]
  env_list = [
    {
      name        = "OAUTH2_PROXY_CLIENT_ID"
      secret_name = module.secret_oauth2_proxy.name
      secret_key  = "OAUTH2_PROXY_CLIENT_ID"
    },
    {
      name        = "OAUTH2_PROXY_CLIENT_SECRET"
      secret_name = module.secret_oauth2_proxy.name
      secret_key  = "OAUTH2_PROXY_CLIENT_SECRET"
    },
    {
      name        = "OAUTH2_PROXY_COOKIE_SECRET"
      secret_name = module.secret_oauth2_proxy.name
      secret_key  = "OAUTH2_PROXY_COOKIE_SECRET"
    }
  ]
  plain_env_list    = []
  volume_name       = "config-volume"
  config_map_name   = kubernetes_config_map.oauth2_proxy_config.metadata[0].name
  volume_mount_path = "/config"
}

# ---------- Ingress ----------
module "ingress_controller" {
  source = "./modules/ingress-controller"

  namespace             = module.namespace_llm_app.name
  frontend_service_name = module.llm_frontend.service_name
  frontend_service_port = 80
  oauth2_service_name   = module.oauth2_proxy.service_name
  oauth2_service_port   = 80
  host                  = "mlops-ai.duckdns.org"
  tls_secret_name       = "llm-app-tls"
  cluster_issuer        = "letsencrypt-prod"
  auth_url              = "http://oauth2-proxy-service.llm-app.svc.cluster.local/oauth2/auth"
  auth_signin           = "https://$host/oauth2/start?rd=$request_uri"

  frontend_annotations = {}
  oauth2_annotations   = {}
}

# ---------- ConfigMap ----------
resource "kubernetes_config_map" "oauth2_proxy_config" {
  metadata {
    name      = "oauth2-proxy-config"
    namespace = module.namespace_llm_app.name
  }

  data = {
    "email_whitelist.txt" = <<-EOT
        khacvy17072001@gmail.com
        khacvygaming@gmail.com
        hoan.nc0506@gmail.com
        EOT
  }
}

# ---------- Secret Manager data sources ----------
data "google_secret_manager_secret_version" "gemini" {
  project = var.project_number  # ← Dùng variable
  secret  = "gemini-api-key"
  version = "latest"
}

data "google_secret_manager_secret_version" "langfuse_public" {
  project = var.project_number  # ← Dùng variable
  secret  = "langfuse-public-key"
  version = "latest"
}

data "google_secret_manager_secret_version" "langfuse_secret" {
  project = var.project_number  # ← Dùng variable
  secret  = "langfuse-secret-key"
  version = "latest"
}

data "google_secret_manager_secret_version" "oauth2_proxy_client_id" {
  project = var.project_number  # ← Dùng variable
  secret  = "oauth2-proxy-client-id"
  version = "latest"
}

data "google_secret_manager_secret_version" "oauth2_proxy_client_secret" {
  project = var.project_number  # ← Dùng variable
  secret  = "oauth2-proxy-client-secret"
  version = "latest"
}

data "google_secret_manager_secret_version" "oauth2_proxy_cookie_secret" {
  project = var.project_number  # ← Dùng variable
  secret  = "oauth2-proxy-cookie-secret"
  version = "latest"
}

# ---------- Kubernetes secrets ----------
module "secret_gemini" {
  source = "./modules/k8s-secret"

  name      = "gemini-secret"
  namespace = module.namespace_llm_app.name
  data = {
    GEMINI_API_KEY = data.google_secret_manager_secret_version.gemini.secret_data
  }
}

module "secret_langfuse" {
  source = "./modules/k8s-secret"

  name      = "langfuse-secret"
  namespace = module.namespace_llm_app.name
  data = {
    LANGFUSE_PUBLIC_KEY = data.google_secret_manager_secret_version.langfuse_public.secret_data
    LANGFUSE_SECRET_KEY = data.google_secret_manager_secret_version.langfuse_secret.secret_data
  }
}

module "secret_oauth2_proxy" {
  source = "./modules/k8s-secret"

  name      = "oauth2-proxy-secret"
  namespace = module.namespace_llm_app.name
  data = {
    OAUTH2_PROXY_CLIENT_ID     = data.google_secret_manager_secret_version.oauth2_proxy_client_id.secret_data
    OAUTH2_PROXY_CLIENT_SECRET = data.google_secret_manager_secret_version.oauth2_proxy_client_secret.secret_data
    OAUTH2_PROXY_COOKIE_SECRET = data.google_secret_manager_secret_version.oauth2_proxy_cookie_secret.secret_data
  }
}

# ---------- Cert Manager ----------
module "cert_manager" {
  source = "./modules/cert-manager"

  namespace        = "cert-manager"
  release_name     = "cert-manager"
  chart_repository = "https://charts.jetstack.io"
  chart_name       = "cert-manager"

  chart_set_values = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]

  ingress_class        = "nginx"
  cluster_issuer_email = "khacvy17072001l@gmail.com"

  cluster_issuer_staging_name                    = "letsencrypt-staging"
  cluster_issuer_staging_private_key_secret_name = "letsencrypt-staging-key"
  acme_server_staging                            = "https://acme-staging-v02.api.letsencrypt.org/directory"

  cluster_issuer_production_name                    = "letsencrypt-prod"
  cluster_issuer_production_private_key_secret_name = "letsencrypt-prod-key"
  acme_server_production                            = "https://acme-v02.api.letsencrypt.org/directory"
}