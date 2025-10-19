# IAM Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "create_service_account_keys" {
  description = "Whether to create service account keys for external access"
  type        = bool
  default     = false
}

variable "create_custom_role" {
  description = "Whether to create a custom IAM role with specific permissions"
  type        = bool
  default     = false
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for GKE integration"
  type        = bool
  default     = false
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for Workload Identity (if enabled)"
  type        = string
  default     = "default"
}

variable "enable_github_actions_impersonation" {
  description = "Allow GitHub Actions service account to impersonate service accounts"
  type        = bool
  default     = true
}