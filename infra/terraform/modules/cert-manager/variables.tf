variable "namespace" {}
variable "release_name" {}
variable "chart_repository" {}
variable "chart_name" {}

variable "chart_set_values" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "ingress_class" {}

variable "cluster_issuer_email" {}

variable "cluster_issuer_staging_name" {}
variable "cluster_issuer_staging_private_key_secret_name" {}
variable "acme_server_staging" {}

variable "cluster_issuer_production_name" {}
variable "cluster_issuer_production_private_key_secret_name" {}
variable "acme_server_production" {}