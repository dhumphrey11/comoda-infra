# Terraform Variables for Comoda Infrastructure
# This file defines all input variables used throughout the Terraform configuration

# Project Configuration
variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be between 6 and 30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "The GCP region where regional resources will be created"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone where zonal resources will be created"
  type        = string
  default     = "us-central1-a"
}

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Cloud Run Configuration
variable "cloud_run_services" {
  description = "Configuration for Cloud Run services"
  type = map(object({
    cpu_limit       = optional(string, "1000m")
    memory_limit    = optional(string, "512Mi")
    min_instances   = optional(number, 0)
    max_instances   = optional(number, 10)
    timeout_seconds = optional(number, 300)
    port           = optional(number, 8080)
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

# Storage Configuration
variable "storage_buckets" {
  description = "Configuration for Cloud Storage buckets"
  type = map(object({
    location                    = optional(string, "US")
    storage_class              = optional(string, "STANDARD")
    versioning_enabled         = optional(bool, true)
    lifecycle_rules_enabled    = optional(bool, true)
    lifecycle_delete_age_days  = optional(number, 365)
    uniform_bucket_level_access = optional(bool, true)
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

# Secret Manager Configuration
variable "secrets" {
  description = "List of secrets to create in Secret Manager"
  type = map(object({
    description = string
    labels      = optional(map(string), {})
  }))
  default = {
    database_url = {
      description = "Database connection string"
      labels = {
        service = "backend"
        type    = "database"
      }
    }
    api_keys = {
      description = "External API keys"
      labels = {
        service = "backend"
        type    = "api"
      }
    }
    jwt_secret = {
      description = "JWT signing secret"
      labels = {
        service = "backend"
        type    = "auth"
      }
    }
    ml_model_config = {
      description = "ML model configuration"
      labels = {
        service = "ml"
        type    = "config"
      }
    }
  }
}

# Pub/Sub Configuration
variable "pubsub_topics" {
  description = "Configuration for Pub/Sub topics and subscriptions"
  type = map(object({
    description                = string
    message_retention_duration = optional(string, "604800s") # 7 days
    subscription_configs = optional(map(object({
      ack_deadline_seconds       = optional(number, 20)
      message_retention_duration = optional(string, "604800s")
      retain_acked_messages     = optional(bool, false)
      filter                    = optional(string, "")
      dead_letter_policy = optional(object({
        dead_letter_topic     = string
        max_delivery_attempts = number
      }), null)
    })), {})
  }))
  default = {
    data_processing = {
      description                = "Topic for data processing jobs"
      message_retention_duration = "86400s" # 1 day
      subscription_configs = {
        backend_processor = {
          ack_deadline_seconds = 60
          filter              = ""
        }
        ml_processor = {
          ack_deadline_seconds = 300
          filter              = "attributes.processor_type=\"ml\""
        }
      }
    }
    model_training = {
      description                = "Topic for ML model training events"
      message_retention_duration = "86400s"
      subscription_configs = {
        ml_trainer = {
          ack_deadline_seconds = 600
        }
      }
    }
    notifications = {
      description                = "Topic for user notifications"
      message_retention_duration = "259200s" # 3 days
      subscription_configs = {
        notification_service = {
          ack_deadline_seconds = 30
        }
      }
    }
    backfill_jobs = {
      description                = "Topic for backfill job coordination"
      message_retention_duration = "86400s"
      subscription_configs = {
        backfill_worker = {
          ack_deadline_seconds = 1800 # 30 minutes
        }
      }
    }
  }
}

# Cloud Scheduler Configuration
variable "scheduler_jobs" {
  description = "Configuration for Cloud Scheduler jobs"
  type = map(object({
    description      = string
    schedule        = string # Cron format
    time_zone       = optional(string, "UTC")
    target_topic    = string
    payload         = optional(string, "{}")
    attributes      = optional(map(string), {})
  }))
  default = {
    daily_model_training = {
      description  = "Daily ML model training job"
      schedule     = "0 2 * * *" # Daily at 2 AM UTC
      time_zone    = "UTC"
      target_topic = "model_training"
      payload      = jsonencode({
        job_type = "daily_training"
        priority = "normal"
      })
      attributes = {
        source = "scheduler"
        type   = "training"
      }
    }
    hourly_data_processing = {
      description  = "Hourly data processing job"
      schedule     = "0 * * * *" # Every hour
      time_zone    = "UTC"
      target_topic = "data_processing"
      payload      = jsonencode({
        job_type = "hourly_batch"
        priority = "high"
      })
      attributes = {
        source = "scheduler"
        type   = "processing"
      }
    }
    weekly_cleanup = {
      description  = "Weekly cleanup job"
      schedule     = "0 3 * * 0" # Weekly on Sunday at 3 AM UTC
      time_zone    = "UTC"
      target_topic = "backfill_jobs"
      payload      = jsonencode({
        job_type = "cleanup"
        priority = "low"
      })
      attributes = {
        source = "scheduler"
        type   = "cleanup"
      }
    }
  }
}

# Labels and Tags
variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    project     = "comoda"
    managed_by  = "terraform"
    team        = "engineering"
  }
}

# Network Configuration
variable "vpc_connector_name" {
  description = "Name of the VPC connector for Cloud Run services (if using custom VPC)"
  type        = string
  default     = ""
}

variable "allowed_ingress_cidrs" {
  description = "List of CIDR blocks allowed to access Cloud Run services"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Allow all by default, restrict in production
}