# Pub/Sub Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "subscription_expiration_ttl" {
  description = "TTL for subscription expiration policy"
  type        = string
  default     = "2678400s" # 31 days
}