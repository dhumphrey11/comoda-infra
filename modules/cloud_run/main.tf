# Cloud Run Services Module
# This module creates and configures all Cloud Run services for the Comoda application

# Local variables for service configuration
locals {
  services = {
    backend = {
      description     = "Backend API service for Comoda application"
      cpu_limit       = var.cloud_run_config.backend.cpu_limit
      memory_limit    = var.cloud_run_config.backend.memory_limit
      min_instances   = var.cloud_run_config.backend.min_instances
      max_instances   = var.cloud_run_config.backend.max_instances
      timeout_seconds = var.cloud_run_config.backend.timeout_seconds
      port           = var.cloud_run_config.backend.port
      environment_variables = {
        GCP_PROJECT_ID     = var.project_id
        GCP_REGION        = var.region
        DATA_BUCKET       = var.storage_buckets.comoda_data
        MODELS_BUCKET     = var.storage_buckets.comoda_models
        PUBSUB_TOPICS     = jsonencode(var.pubsub_topics)
        SECRET_PREFIX     = "projects/${var.project_id}/secrets"
        SERVICE_NAME      = "backend"
      }
    }
    frontend = {
      description     = "Frontend web application for Comoda"
      cpu_limit       = var.cloud_run_config.frontend.cpu_limit
      memory_limit    = var.cloud_run_config.frontend.memory_limit
      min_instances   = var.cloud_run_config.frontend.min_instances
      max_instances   = var.cloud_run_config.frontend.max_instances
      timeout_seconds = var.cloud_run_config.frontend.timeout_seconds
      port           = var.cloud_run_config.frontend.port
      environment_variables = {
        GCP_PROJECT_ID = var.project_id
        GCP_REGION    = var.region
        SERVICE_NAME  = "frontend"
        NODE_ENV     = "production"
      }
    }
    ml = {
      description     = "Machine Learning service for model training and inference"
      cpu_limit       = var.cloud_run_config.ml.cpu_limit
      memory_limit    = var.cloud_run_config.ml.memory_limit
      min_instances   = var.cloud_run_config.ml.min_instances
      max_instances   = var.cloud_run_config.ml.max_instances
      timeout_seconds = var.cloud_run_config.ml.timeout_seconds
      port           = var.cloud_run_config.ml.port
      environment_variables = {
        GCP_PROJECT_ID = var.project_id
        GCP_REGION    = var.region
        DATA_BUCKET   = var.storage_buckets.comoda_data
        MODELS_BUCKET = var.storage_buckets.comoda_models
        PUBSUB_TOPICS = jsonencode(var.pubsub_topics)
        SECRET_PREFIX = "projects/${var.project_id}/secrets"
        SERVICE_NAME  = "ml"
        PYTHONPATH   = "/app"
      }
    }
    backfill = {
      description     = "Data backfill and batch processing service"
      cpu_limit       = var.cloud_run_config.backfill.cpu_limit
      memory_limit    = var.cloud_run_config.backfill.memory_limit
      min_instances   = var.cloud_run_config.backfill.min_instances
      max_instances   = var.cloud_run_config.backfill.max_instances
      timeout_seconds = var.cloud_run_config.backfill.timeout_seconds
      port           = var.cloud_run_config.backfill.port
      environment_variables = {
        GCP_PROJECT_ID = var.project_id
        GCP_REGION    = var.region
        DATA_BUCKET   = var.storage_buckets.comoda_data
        PUBSUB_TOPICS = jsonencode(var.pubsub_topics)
        SECRET_PREFIX = "projects/${var.project_id}/secrets"
        SERVICE_NAME  = "backfill"
      }
    }
  }
}

# Cloud Run services
resource "google_cloud_run_v2_service" "services" {
  for_each = local.services

  name     = each.key
  location = var.region
  project  = var.project_id

  template {
    # Use service-specific service account
    service_account = var.service_accounts[each.key].email

    # Scaling configuration
    scaling {
      min_instance_count = each.value.min_instances
      max_instance_count = each.value.max_instances
    }

    containers {
      # Placeholder image - will be updated during deployment
      image = "gcr.io/cloudrun/hello"

      # Resource limits
      resources {
        limits = {
          cpu    = each.value.cpu_limit
          memory = each.value.memory_limit
        }
        cpu_idle = each.value.min_instances > 0 ? false : true
      }

      # Port configuration
      ports {
        container_port = each.value.port
      }

      # Environment variables
      dynamic "env" {
        for_each = each.value.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret environment variables (references to Secret Manager)
      dynamic "env" {
        for_each = var.secret_ids
        content {
          name = upper("${env.key}_SECRET")
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      # Health check and startup probe
      startup_probe {
        http_get {
          path = "/health"
          port = each.value.port
        }
        initial_delay_seconds = 10
        timeout_seconds      = 5
        period_seconds       = 10
        failure_threshold    = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = each.value.port
        }
        initial_delay_seconds = 30
        timeout_seconds      = 5
        period_seconds       = 30
        failure_threshold    = 3
      }
    }

    # Timeout configuration
    timeout = "${each.value.timeout_seconds}s"

    # Annotations for additional configuration
    annotations = {
      "autoscaling.knative.dev/maxScale" = tostring(each.value.max_instances)
      "autoscaling.knative.dev/minScale" = tostring(each.value.min_instances)
      "run.googleapis.com/execution-environment" = "gen2"
      "run.googleapis.com/cpu-throttling" = "false"
    }
  }

  # Metadata
  annotations = {
    "run.googleapis.com/ingress" = each.key == "frontend" ? "all" : "internal-and-cloud-load-balancing"
    "run.googleapis.com/description" = each.value.description
  }

  labels = {
    service     = each.key
    project     = "comoda"
    managed_by  = "terraform"
    environment = var.environment
  }

  # Lifecycle configuration
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image, # Ignore image changes (handled by CI/CD)
    ]
  }
}

# IAM policy for public access (frontend only)
resource "google_cloud_run_service_iam_member" "public_access" {
  count = var.allow_public_access ? 1 : 0

  location = google_cloud_run_v2_service.services["frontend"].location
  project  = google_cloud_run_v2_service.services["frontend"].project
  service  = google_cloud_run_v2_service.services["frontend"].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM policy for internal service communication
resource "google_cloud_run_service_iam_member" "service_access" {
  for_each = {
    for service_name, service_account in var.service_accounts : service_name => service_account
    if service_name != "frontend" # Frontend doesn't need to invoke other services directly
  }

  location = google_cloud_run_v2_service.services[each.key].location
  project  = google_cloud_run_v2_service.services[each.key].project
  service  = google_cloud_run_v2_service.services[each.key].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_accounts["backend"].email}"
}

# Domain mapping (optional - uncomment and configure if using custom domains)
# resource "google_cloud_run_domain_mapping" "domain" {
#   for_each = var.custom_domains
#   
#   location = var.region
#   name     = each.value
#   
#   metadata {
#     namespace = var.project_id
#   }
#   
#   spec {
#     route_name = google_cloud_run_v2_service.services[each.key].name
#   }
# }