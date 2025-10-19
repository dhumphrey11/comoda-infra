# Pub/Sub Module
# This module creates Pub/Sub topics and subscriptions for asynchronous communication

# Local variables for topic and subscription configuration
locals {
  topics = {
    data_processing = {
      description                = "Topic for data processing job coordination"
      message_retention_duration = "86400s" # 24 hours
      message_storage_policy = {
        allowed_persistence_regions = ["us-central1", "us-east1"]
      }
      labels = {
        purpose = "data-processing"
        service = "backend"
      }
    }
    model_training = {
      description                = "Topic for ML model training events and coordination"
      message_retention_duration = "86400s"
      message_storage_policy = {
        allowed_persistence_regions = ["us-central1"]
      }
      labels = {
        purpose = "ml-training"
        service = "ml"
      }
    }
    notifications = {
      description                = "Topic for user notifications and alerts"
      message_retention_duration = "259200s" # 3 days
      message_storage_policy = {
        allowed_persistence_regions = ["us-central1", "us-east1"]
      }
      labels = {
        purpose = "notifications"
        service = "backend"
      }
    }
    backfill_jobs = {
      description                = "Topic for backfill job coordination and status updates"
      message_retention_duration = "86400s"
      message_storage_policy = {
        allowed_persistence_regions = ["us-central1"]
      }
      labels = {
        purpose = "backfill"
        service = "backfill"
      }
    }
    dead_letter = {
      description                = "Dead letter topic for failed message processing"
      message_retention_duration = "604800s" # 7 days
      message_storage_policy = {
        allowed_persistence_regions = ["us-central1"]
      }
      labels = {
        purpose = "dead-letter"
        service = "all"
      }
    }
  }

  subscriptions = {
    # Data Processing Subscriptions
    backend_data_processor = {
      topic_name               = "data_processing"
      ack_deadline_seconds     = 60
      message_retention_duration = "604800s" # 7 days
      retain_acked_messages    = false
      enable_message_ordering  = true
      filter                  = ""
      dead_letter_policy = {
        dead_letter_topic     = "dead_letter"
        max_delivery_attempts = 5
      }
      retry_policy = {
        minimum_backoff = "10s"
        maximum_backoff = "600s"
      }
      labels = {
        service = "backend"
        type    = "processor"
      }
    }
    ml_data_processor = {
      topic_name               = "data_processing"
      ack_deadline_seconds     = 300 # 5 minutes for ML processing
      message_retention_duration = "604800s"
      retain_acked_messages    = false
      enable_message_ordering  = false
      filter                  = "attributes.processor_type=\"ml\""
      dead_letter_policy = {
        dead_letter_topic     = "dead_letter"
        max_delivery_attempts = 3
      }
      retry_policy = {
        minimum_backoff = "30s"
        maximum_backoff = "1800s" # 30 minutes
      }
      labels = {
        service = "ml"
        type    = "processor"
      }
    }

    # Model Training Subscriptions
    ml_trainer = {
      topic_name               = "model_training"
      ack_deadline_seconds     = 600 # 10 minutes for training jobs
      message_retention_duration = "604800s"
      retain_acked_messages    = false
      enable_message_ordering  = true
      filter                  = ""
      dead_letter_policy = {
        dead_letter_topic     = "dead_letter"
        max_delivery_attempts = 2
      }
      retry_policy = {
        minimum_backoff = "60s"
        maximum_backoff = "3600s" # 1 hour
      }
      labels = {
        service = "ml"
        type    = "trainer"
      }
    }

    # Notification Subscriptions
    notification_service = {
      topic_name               = "notifications"
      ack_deadline_seconds     = 30
      message_retention_duration = "259200s" # 3 days
      retain_acked_messages    = false
      enable_message_ordering  = false
      filter                  = ""
      dead_letter_policy = {
        dead_letter_topic     = "dead_letter"
        max_delivery_attempts = 5
      }
      retry_policy = {
        minimum_backoff = "5s"
        maximum_backoff = "300s" # 5 minutes
      }
      labels = {
        service = "backend"
        type    = "notification"
      }
    }

    # Backfill Subscriptions
    backfill_worker = {
      topic_name               = "backfill_jobs"
      ack_deadline_seconds     = 1800 # 30 minutes for backfill jobs
      message_retention_duration = "86400s"
      retain_acked_messages    = false
      enable_message_ordering  = true
      filter                  = ""
      dead_letter_policy = {
        dead_letter_topic     = "dead_letter"
        max_delivery_attempts = 3
      }
      retry_policy = {
        minimum_backoff = "120s"
        maximum_backoff = "7200s" # 2 hours
      }
      labels = {
        service = "backfill"
        type    = "worker"
      }
    }

    # Dead Letter Subscription (for monitoring failed messages)
    dead_letter_monitor = {
      topic_name               = "dead_letter"
      ack_deadline_seconds     = 60
      message_retention_duration = "604800s"
      retain_acked_messages    = true
      enable_message_ordering  = false
      filter                  = ""
      dead_letter_policy       = null # No dead letter for dead letter queue
      retry_policy = {
        minimum_backoff = "10s"
        maximum_backoff = "600s"
      }
      labels = {
        service = "monitoring"
        type    = "dead-letter"
      }
    }
  }
}

# Create Pub/Sub topics
resource "google_pubsub_topic" "topics" {
  for_each = local.topics

  name    = each.key
  project = var.project_id

  message_retention_duration = each.value.message_retention_duration

  message_storage_policy {
    allowed_persistence_regions = each.value.message_storage_policy.allowed_persistence_regions
  }

  labels = merge(
    {
      project    = "comoda"
      managed_by = "terraform"
      environment = var.environment
    },
    each.value.labels
  )
}

# Create Pub/Sub subscriptions
resource "google_pubsub_subscription" "subscriptions" {
  for_each = local.subscriptions

  name    = each.key
  topic   = google_pubsub_topic.topics[each.value.topic_name].name
  project = var.project_id

  ack_deadline_seconds       = each.value.ack_deadline_seconds
  message_retention_duration = each.value.message_retention_duration
  retain_acked_messages     = each.value.retain_acked_messages
  enable_message_ordering   = each.value.enable_message_ordering
  filter                   = each.value.filter != "" ? each.value.filter : null

  # Dead letter policy (if specified)
  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_policy != null ? [each.value.dead_letter_policy] : []
    content {
      dead_letter_topic     = google_pubsub_topic.topics[dead_letter_policy.value.dead_letter_topic].id
      max_delivery_attempts = dead_letter_policy.value.max_delivery_attempts
    }
  }

  # Retry policy
  retry_policy {
    minimum_backoff = each.value.retry_policy.minimum_backoff
    maximum_backoff = each.value.retry_policy.maximum_backoff
  }

  # Expiration policy (optional - subscriptions expire after 31 days of inactivity by default)
  expiration_policy {
    ttl = var.subscription_expiration_ttl
  }

  labels = merge(
    {
      project    = "comoda"
      managed_by = "terraform"
      environment = var.environment
    },
    each.value.labels
  )

  depends_on = [google_pubsub_topic.topics]
}

# IAM bindings for service accounts
resource "google_pubsub_topic_iam_member" "topic_publishers" {
  for_each = {
    # Backend can publish to all topics except dead letter
    "data_processing_backend"  = { topic = "data_processing", member = "serviceAccount:comoda-backend@${var.project_id}.iam.gserviceaccount.com" }
    "notifications_backend"    = { topic = "notifications", member = "serviceAccount:comoda-backend@${var.project_id}.iam.gserviceaccount.com" }
    "model_training_backend"   = { topic = "model_training", member = "serviceAccount:comoda-backend@${var.project_id}.iam.gserviceaccount.com" }
    
    # ML service can publish to model training and notifications
    "model_training_ml"        = { topic = "model_training", member = "serviceAccount:comoda-ml@${var.project_id}.iam.gserviceaccount.com" }
    "notifications_ml"         = { topic = "notifications", member = "serviceAccount:comoda-ml@${var.project_id}.iam.gserviceaccount.com" }
    
    # Backfill service can publish to backfill jobs and notifications
    "backfill_jobs_backfill"   = { topic = "backfill_jobs", member = "serviceAccount:comoda-backfill@${var.project_id}.iam.gserviceaccount.com" }
    "notifications_backfill"   = { topic = "notifications", member = "serviceAccount:comoda-backfill@${var.project_id}.iam.gserviceaccount.com" }
  }

  topic   = google_pubsub_topic.topics[each.value.topic].name
  role    = "roles/pubsub.publisher"
  member  = each.value.member
  project = var.project_id

  depends_on = [google_pubsub_topic.topics]
}

resource "google_pubsub_subscription_iam_member" "subscription_subscribers" {
  for_each = {
    # Backend service subscribers
    "backend_data_processor"   = { subscription = "backend_data_processor", member = "serviceAccount:comoda-backend@${var.project_id}.iam.gserviceaccount.com" }
    "notification_service"     = { subscription = "notification_service", member = "serviceAccount:comoda-backend@${var.project_id}.iam.gserviceaccount.com" }
    
    # ML service subscribers
    "ml_data_processor"        = { subscription = "ml_data_processor", member = "serviceAccount:comoda-ml@${var.project_id}.iam.gserviceaccount.com" }
    "ml_trainer"              = { subscription = "ml_trainer", member = "serviceAccount:comoda-ml@${var.project_id}.iam.gserviceaccount.com" }
    
    # Backfill service subscribers
    "backfill_worker"         = { subscription = "backfill_worker", member = "serviceAccount:comoda-backfill@${var.project_id}.iam.gserviceaccount.com" }
    
    # Monitoring access to dead letter queue
    "dead_letter_monitor"     = { subscription = "dead_letter_monitor", member = "serviceAccount:comoda-backend@${var.project_id}.iam.gserviceaccount.com" }
  }

  subscription = google_pubsub_subscription.subscriptions[each.value.subscription].name
  role        = "roles/pubsub.subscriber"
  member      = each.value.member
  project     = var.project_id

  depends_on = [google_pubsub_subscription.subscriptions]
}