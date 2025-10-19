variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default region for regional resources (e.g., us-central1)"
  type        = string
}

variable "location" {
  description = "Location for multi-regional resources (e.g., US)"
  type        = string
}
