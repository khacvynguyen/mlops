variable "namespace" {}
variable "frontend_service_name" {}
variable "frontend_service_port" { type = number }
variable "oauth2_service_name" {}
variable "oauth2_service_port" { type = number }
variable "host" {}
variable "tls_secret_name" {}
variable "cluster_issuer" {}
variable "auth_url" {}
variable "auth_signin" {}

variable "frontend_annotations" {
  type    = map(string)
  default = {}
}

variable "oauth2_annotations" {
  type    = map(string)
  default = {}
}