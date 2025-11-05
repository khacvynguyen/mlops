provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

provider "google" {
  project     = var.project_id
  region      = "asia-southeast1"
  credentials = file(var.google_credentials_path)
}