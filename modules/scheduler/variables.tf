# Cloud Scheduler Module Variables

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

variable "pubsub_topics" {
  description = "Map of Pub/Sub topic names"
  type        = map(string)
}

variable "create_scheduler_service_account" {
  description = "Whether to create a dedicated service account for Cloud Scheduler"
  type        = bool
  default     = false
}

variable "enable_http_jobs" {
  description = "Whether to enable HTTP target scheduler jobs"
  type        = bool
  default     = false
}

variable "http_job_configs" {
  description = "Configuration for HTTP target scheduler jobs"
  type = map(object({
    description        = string
    schedule          = string
    time_zone         = string
    uri               = string
    http_method       = string
    headers           = map(string)
    body              = string
    retry_count       = number
    max_retry_duration = string
  }))
  default = {}
}

variable "enable_scheduler_monitoring" {
  description = "Whether to enable monitoring and alerting for scheduler jobs"
  type        = bool
  default     = false
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}