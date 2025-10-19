# Cloud Scheduler Module
# This module creates Cloud Scheduler jobs for automated task execution

# Local variables for scheduler job configuration
locals {
  scheduler_jobs = {
    daily_model_training = {
      description   = "Daily ML model training and evaluation job"
      schedule      = "0 2 * * *" # Daily at 2 AM UTC
      time_zone     = "UTC"
      target_topic  = var.pubsub_topics.model_training
      payload = jsonencode({
        job_type     = "daily_training"
        priority     = "normal"
        trigger_time = "scheduled"
        models       = ["recommendation", "classification"]
      })
      attributes = {
        source      = "scheduler"
        job_type    = "training"
        frequency   = "daily"
        environment = var.environment
      }
    }
    
    hourly_data_processing = {
      description   = "Hourly batch data processing job"
      schedule      = "0 * * * *" # Every hour at minute 0
      time_zone     = "UTC"
      target_topic  = var.pubsub_topics.data_processing
      payload = jsonencode({
        job_type       = "hourly_batch"
        priority       = "high"
        trigger_time   = "scheduled"
        process_types  = ["incremental", "validation"]
      })
      attributes = {
        source      = "scheduler"
        job_type    = "processing"
        frequency   = "hourly"
        environment = var.environment
      }
    }
    
    weekly_cleanup = {
      description   = "Weekly cleanup and maintenance job"
      schedule      = "0 3 * * 0" # Weekly on Sunday at 3 AM UTC
      time_zone     = "UTC"
      target_topic  = var.pubsub_topics.backfill_jobs
      payload = jsonencode({
        job_type    = "cleanup"
        priority    = "low"
        trigger_time = "scheduled"
        cleanup_types = ["logs", "temp_files", "old_models"]
      })
      attributes = {
        source      = "scheduler"
        job_type    = "cleanup"
        frequency   = "weekly"
        environment = var.environment
      }
    }
    
    monthly_analytics = {
      description   = "Monthly analytics and reporting job"
      schedule      = "0 4 1 * *" # Monthly on the 1st at 4 AM UTC
      time_zone     = "UTC"
      target_topic  = var.pubsub_topics.data_processing
      payload = jsonencode({
        job_type    = "monthly_analytics"
        priority    = "normal"
        trigger_time = "scheduled"
        report_types = ["usage", "performance", "costs"]
      })
      attributes = {
        source      = "scheduler"
        job_type    = "analytics"
        frequency   = "monthly"
        environment = var.environment
      }
    }
    
    health_check = {
      description   = "System health check and monitoring job"
      schedule      = "*/15 * * * *" # Every 15 minutes
      time_zone     = "UTC"
      target_topic  = var.pubsub_topics.notifications
      payload = jsonencode({
        job_type    = "health_check"
        priority    = "high"
        trigger_time = "scheduled"
        check_types = ["services", "storage", "ml_models"]
      })
      attributes = {
        source      = "scheduler"
        job_type    = "monitoring"
        frequency   = "15min"
        environment = var.environment
      }
    }
  }
}

# Create Cloud Scheduler jobs
resource "google_cloud_scheduler_job" "scheduler_jobs" {
  for_each = local.scheduler_jobs

  name        = each.key
  description = each.value.description
  schedule    = each.value.schedule
  time_zone   = each.value.time_zone
  region      = var.region
  project     = var.project_id

  # Pub/Sub target configuration
  pubsub_target {
    topic_name = "projects/${var.project_id}/topics/${each.value.target_topic}"
    data       = base64encode(each.value.payload)
    
    # Add attributes for message filtering and routing
    attributes = each.value.attributes
  }

  # Retry configuration
  retry_config {
    retry_count          = 3
    max_retry_duration   = "300s" # 5 minutes
    min_backoff_duration = "5s"
    max_backoff_duration = "60s"
    max_doublings        = 3
  }

  # Attempt deadline
  attempt_deadline = "320s" # Slightly longer than max_retry_duration

  lifecycle {
    # Prevent destruction if job is paused (useful for maintenance)
    prevent_destroy = false
  }
}

# Create a service account for Cloud Scheduler (if needed for custom authentication)
resource "google_service_account" "scheduler_sa" {
  count = var.create_scheduler_service_account ? 1 : 0

  account_id   = "comoda-scheduler"
  display_name = "Comoda Cloud Scheduler Service Account"
  description  = "Service account for Cloud Scheduler jobs authentication"
  project      = var.project_id
}

# Grant Pub/Sub publisher role to scheduler service account
resource "google_project_iam_member" "scheduler_pubsub_publisher" {
  count = var.create_scheduler_service_account ? 1 : 0

  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.scheduler_sa[0].email}"
}

# Alternative HTTP target jobs (for direct service invocation)
resource "google_cloud_scheduler_job" "http_jobs" {
  for_each = var.enable_http_jobs ? var.http_job_configs : {}

  name        = each.key
  description = each.value.description
  schedule    = each.value.schedule
  time_zone   = each.value.time_zone
  region      = var.region
  project     = var.project_id

  http_target {
    uri         = each.value.uri
    http_method = each.value.http_method

    # Authentication for Cloud Run services
    oidc_token {
      service_account_email = var.create_scheduler_service_account ? google_service_account.scheduler_sa[0].email : "comoda-backend@${var.project_id}.iam.gserviceaccount.com"
    }

    # Request headers
    headers = merge(
      {
        "Content-Type" = "application/json"
        "User-Agent"   = "Google-Cloud-Scheduler"
      },
      each.value.headers
    )

    # Request body
    body = base64encode(each.value.body)
  }

  retry_config {
    retry_count        = each.value.retry_count
    max_retry_duration = each.value.max_retry_duration
  }
}

# Monitoring and alerting for scheduler jobs (optional)
resource "google_monitoring_alert_policy" "scheduler_failure_alert" {
  count = var.enable_scheduler_monitoring ? 1 : 0

  display_name = "Cloud Scheduler Job Failures - Comoda"
  project      = var.project_id

  conditions {
    display_name = "Scheduler job failure rate"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_scheduler_job\" AND resource.labels.project_id=\"${var.project_id}\""
      duration        = "300s" # 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.labels.job_id"]
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s" # Auto close after 30 minutes
  }

  enabled = true

  depends_on = [google_cloud_scheduler_job.scheduler_jobs]
}