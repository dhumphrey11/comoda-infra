# Cloud Run Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region where Cloud Run services will be deployed"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "artifact_registry_url" {
  description = "The Artifact Registry repository ID for container images"
  type        = string
}

variable "cloud_run_config" {
  description = "Configuration for Cloud Run services"
  type = map(object({
    cpu_limit       = string
    memory_limit    = string
    min_instances   = number
    max_instances   = number
    timeout_seconds = number
    port           = number
  }))
  default = {
    backend = {
      cpu_limit       = "2000m"
      memory_limit    = "1Gi"
      min_instances   = 1
      max_instances   = 20
      timeout_seconds = 300
      port           = 8080
    }
    frontend = {
      cpu_limit       = "1000m"
      memory_limit    = "512Mi"
      min_instances   = 1
      max_instances   = 10
      timeout_seconds = 60
      port           = 3000
    }
    ml = {
      cpu_limit       = "4000m"
      memory_limit    = "4Gi"
      min_instances   = 0
      max_instances   = 5
      timeout_seconds = 900
      port           = 8080
    }
    backfill = {
      cpu_limit       = "2000m"
      memory_limit    = "2Gi"
      min_instances   = 0
      max_instances   = 3
      timeout_seconds = 3600
      port           = 8080
    }
  }
}

variable "service_accounts" {
  description = "Service accounts for each Cloud Run service"
  type = map(object({
    email = string
    name  = string
  }))
}

variable "storage_buckets" {
  description = "Names of storage buckets"
  type        = map(string)
}

variable "secret_ids" {
  description = "Secret Manager secret IDs"
  type        = map(string)
}

variable "pubsub_topics" {
  description = "Pub/Sub topic names"
  type        = map(string)
}

variable "allow_public_access" {
  description = "Whether to allow public access to frontend service"
  type        = bool
  default     = true
}

variable "custom_domains" {
  description = "Custom domains for services (optional)"
  type        = map(string)
  default     = {}
}

variable "vpc_connector_name" {
  description = "Name of the VPC connector (if using custom VPC)"
  type        = string
  default     = ""
}