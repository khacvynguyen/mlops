variable "namespace" {}
variable "service_name" {}
variable "deployment_name" {}
variable "container_name" {}
variable "image" {}
variable "replicas" { type = number }
variable "selector_map" { type = map(string) }
variable "port" { type = number }
variable "target_port" { type = number }
variable "container_port" { type = number }
variable "env_list" {
  type = list(object({
    name        = string
    secret_name = string
    secret_key  = string
  }))
  default = []
}
variable "plain_env_list" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}