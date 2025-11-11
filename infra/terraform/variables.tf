variable "project_id" {
  type        = string
  description = "GCP project ID dùng cho các provider/data source"
}

variable "project_number" {
  type        = string
  description = "GCP project number (dùng để truy cập secrets)"
  default     = "83344784907"
}

variable "backend_image" {
  type        = string
  description = "Container image cho deployment backend"
  default     = "asia-southeast1-docker.pkg.dev/mlops-476305/my-mlops/llm-backend:latest"
}

variable "frontend_image" {
  type        = string
  description = "Container image cho deployment frontend"
  default     = "asia-southeast1-docker.pkg.dev/mlops-476305/my-mlops/llm-frontend:latest"
}

variable "backend_replicas" {
  type        = number
  description = "Số lượng replica cho backend"
  default     = 0
}

variable "frontend_replicas" {
  type        = number
  description = "Số lượng replica cho frontend"
  default     = 0
}

variable "oauth2_replicas" {
  type        = number
  description = "Số lượng replica cho oauth2 proxy"
  default     = 0
}

variable "cloudbuild_logs_project_id" {
  type        = string
  description = "Project chứa Cloud Build logs bucket (thường là project number)."
  default     = "83344784907"
}
