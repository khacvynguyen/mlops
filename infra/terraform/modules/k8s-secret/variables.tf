variable "name" { type = string }
variable "namespace" { type = string }

variable "type" {
  type    = string
  default = "Opaque"
}

variable "data" {
  type    = map(string)
  default = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "annotations" {
  type    = map(string)
  default = {}
}