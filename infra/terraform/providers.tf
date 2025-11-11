# Lấy thông tin cluster từ GCP
data "google_container_cluster" "primary" {
  name     = "mlops-cluster"
  location = "asia-southeast1"
  project  = var.project_id
}

# Lấy access token động
data "google_client_config" "default" {}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.primary.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate
    )
  }
}

provider "google" {
  project = var.project_id
  region  = "asia-southeast1"
}