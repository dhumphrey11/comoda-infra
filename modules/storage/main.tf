# Cloud Storage Module
# This module creates and configures Cloud Storage buckets for the Comoda application

# Random suffix for globally unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Local variables for bucket configuration
locals {
  bucket_configs = {
    comoda_data = {
      description                 = "Primary data storage bucket for Comoda application"
      location                   = var.bucket_configs.comoda_data.location
      storage_class              = var.bucket_configs.comoda_data.storage_class
      versioning_enabled         = var.bucket_configs.comoda_data.versioning_enabled
      lifecycle_rules_enabled    = var.bucket_configs.comoda_data.lifecycle_rules_enabled
      lifecycle_delete_age_days  = var.bucket_configs.comoda_data.lifecycle_delete_age_days
      uniform_bucket_level_access = var.bucket_configs.comoda_data.uniform_bucket_level_access
      cors_enabled              = true
      labels = {
        purpose     = "data-storage"
        service     = "backend"
        data_type   = "application-data"
        retention   = "long-term"
      }
    }
    comoda_models = {
      description                 = "ML models and training artifacts storage"
      location                   = var.bucket_configs.comoda_models.location
      storage_class              = var.bucket_configs.comoda_models.storage_class
      versioning_enabled         = var.bucket_configs.comoda_models.versioning_enabled
      lifecycle_rules_enabled    = var.bucket_configs.comoda_models.lifecycle_rules_enabled
      lifecycle_delete_age_days  = var.bucket_configs.comoda_models.lifecycle_delete_age_days
      uniform_bucket_level_access = var.bucket_configs.comoda_models.uniform_bucket_level_access
      cors_enabled              = false
      labels = {
        purpose     = "model-storage"
        service     = "ml"
        data_type   = "ml-models"
        retention   = "medium-term"
      }
    }
  }
  
  # Generate unique bucket names
  bucket_names = {
    for name, config in local.bucket_configs : name => "${name}-${var.project_id}-${random_id.bucket_suffix.hex}"
  }
}

# Cloud Storage buckets
resource "google_storage_bucket" "buckets" {
  for_each = local.bucket_configs

  name          = local.bucket_names[each.key]
  location      = each.value.location
  storage_class = each.value.storage_class
  project       = var.project_id

  # Force destroy for development - set to false for production
  force_destroy = var.environment == "dev" ? true : false

  # Uniform bucket-level access
  uniform_bucket_level_access = each.value.uniform_bucket_level_access

  # Versioning configuration
  versioning {
    enabled = each.value.versioning_enabled
  }

  # Lifecycle rules for automatic cleanup
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules_enabled ? [1] : []
    
    content {
      condition {
        age = each.value.lifecycle_delete_age_days
      }
      action {
        type = "Delete"
      }
    }
  }

  # Additional lifecycle rule for non-current versions
  dynamic "lifecycle_rule" {
    for_each = each.value.versioning_enabled && each.value.lifecycle_rules_enabled ? [1] : []
    
    content {
      condition {
        num_newer_versions = 3
      }
      action {
        type = "Delete"
      }
    }
  }

  # CORS configuration for data bucket (to allow web uploads)
  dynamic "cors" {
    for_each = each.value.cors_enabled ? [1] : []
    
    content {
      origin          = ["https://*.${var.project_id}.a.run.app", "https://localhost:3000"]
      method          = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      response_header = ["Content-Type", "Access-Control-Allow-Origin"]
      max_age_seconds = 3600
    }
  }

  # Encryption (using Google-managed keys by default)
  # Uncomment and configure if using customer-managed keys
  # encryption {
  #   default_kms_key_name = var.kms_key_name
  # }

  # Labels for organization and billing
  labels = merge(
    {
      project     = "comoda"
      managed_by  = "terraform"
      environment = var.environment
    },
    each.value.labels
  )

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Bucket IAM bindings for service accounts
resource "google_storage_bucket_iam_member" "bucket_access" {
  for_each = {
    # Backend service needs access to both buckets
    "backend_data_admin"   = {
      bucket = local.bucket_names["comoda_data"]
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:comoda-backend@${var.project_id}.iam.gserviceaccount.com"
    }
    "backend_models_admin" = {
      bucket = local.bucket_names["comoda_models"]
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:comoda-backend@${var.project_id}.iam.gserviceaccount.com"
    }
    # ML service needs full access to models bucket and read access to data bucket
    "ml_data_viewer" = {
      bucket = local.bucket_names["comoda_data"]
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:comoda-ml@${var.project_id}.iam.gserviceaccount.com"
    }
    "ml_models_admin" = {
      bucket = local.bucket_names["comoda_models"]
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:comoda-ml@${var.project_id}.iam.gserviceaccount.com"
    }
    # Backfill service needs read/write access to data bucket
    "backfill_data_admin" = {
      bucket = local.bucket_names["comoda_data"]
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:comoda-backfill@${var.project_id}.iam.gserviceaccount.com"
    }
  }

  bucket = each.value.bucket
  role   = each.value.role
  member = each.value.member

  depends_on = [google_storage_bucket.buckets]
}

# Notification configuration for Pub/Sub (optional - for real-time processing)
resource "google_storage_notification" "data_bucket_notification" {
  count = var.enable_pubsub_notifications ? 1 : 0

  bucket         = google_storage_bucket.buckets["comoda_data"].name
  payload_format = "JSON_API_V1"
  topic          = "projects/${var.project_id}/topics/data-processing"
  
  event_types = [
    "OBJECT_FINALIZE",
    "OBJECT_DELETE"
  ]

  custom_attributes = {
    source_bucket = "comoda_data"
    notification_type = "storage_event"
  }

  depends_on = [google_storage_bucket.buckets]
}

# Bucket policy document for additional security (if needed)
data "google_iam_policy" "bucket_policy" {
  count = var.enable_bucket_policy_restrictions ? 1 : 0
  
  binding {
    role = "roles/storage.legacyBucketReader"
    members = [
      "projectEditor:${var.project_id}",
      "projectOwner:${var.project_id}",
    ]
  }
  
  binding {
    role = "roles/storage.legacyObjectReader"
    members = [
      "projectViewer:${var.project_id}",
    ]
  }
}

# Apply bucket policy (if enabled)
resource "google_storage_bucket_iam_policy" "bucket_policy" {
  for_each = var.enable_bucket_policy_restrictions ? local.bucket_names : {}

  bucket      = google_storage_bucket.buckets[each.key].name
  policy_data = data.google_iam_policy.bucket_policy[0].policy_data
}