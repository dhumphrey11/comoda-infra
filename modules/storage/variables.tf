# Storage Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "bucket_configs" {
  description = "Configuration for Cloud Storage buckets"
  type = map(object({
    location                    = string
    storage_class              = string
    versioning_enabled         = bool
    lifecycle_rules_enabled    = bool
    lifecycle_delete_age_days  = number
    uniform_bucket_level_access = bool
  }))
  default = {
    comoda_data = {
      location                    = "US"
      storage_class              = "STANDARD"
      versioning_enabled         = true
      lifecycle_rules_enabled    = true
      lifecycle_delete_age_days  = 365
      uniform_bucket_level_access = true
    }
    comoda_models = {
      location                    = "US"
      storage_class              = "STANDARD"
      versioning_enabled         = true
      lifecycle_rules_enabled    = true
      lifecycle_delete_age_days  = 180
      uniform_bucket_level_access = true
    }
  }
}

variable "enable_pubsub_notifications" {
  description = "Enable Pub/Sub notifications for bucket events"
  type        = bool
  default     = false
}

variable "enable_bucket_policy_restrictions" {
  description = "Enable additional IAM policy restrictions on buckets"
  type        = bool
  default     = false
}

variable "kms_key_name" {
  description = "KMS key name for bucket encryption (optional)"
  type        = string
  default     = ""
}