# Terraform Outputs for Comoda Infrastructure
# This file defines output values that provide useful information about the created resources

# Project Information
output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "The GCP project number"
  value       = data.google_project.project.number
}

output "region" {
  description = "The GCP region where resources are deployed"
  value       = var.region
}

# Artifact Registry
output "artifact_registry_repository" {
  description = "The Artifact Registry repository for container images"
  value = {
    id       = google_artifact_registry_repository.comoda_images.id
    location = google_artifact_registry_repository.comoda_images.location
    name     = google_artifact_registry_repository.comoda_images.name
    url      = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.comoda_images.repository_id}"
  }
}

# Cloud Run Services
output "cloud_run_services" {
  description = "Information about deployed Cloud Run services"
  value       = module.cloud_run.services
  sensitive   = false
}

output "cloud_run_urls" {
  description = "URLs of the deployed Cloud Run services"
  value       = module.cloud_run.service_urls
}

# Storage Buckets
output "storage_buckets" {
  description = "Information about created Cloud Storage buckets"
  value       = module.storage.buckets
}

output "storage_bucket_names" {
  description = "Names of the created Cloud Storage buckets"
  value       = module.storage.bucket_names
}

output "storage_bucket_urls" {
  description = "URLs of the created Cloud Storage buckets"
  value       = module.storage.bucket_urls
}

# IAM Service Accounts
output "service_accounts" {
  description = "Information about created service accounts"
  value       = module.iam.service_accounts
}

output "service_account_emails" {
  description = "Email addresses of created service accounts"
  value       = module.iam.service_account_emails
}

# Secret Manager
output "secrets" {
  description = "Information about created Secret Manager secrets"
  value       = module.secrets.secrets
}

output "secret_ids" {
  description = "IDs of created Secret Manager secrets"
  value       = module.secrets.secret_ids
}

# Pub/Sub
output "pubsub_topics" {
  description = "Information about created Pub/Sub topics"
  value       = module.pubsub.topics
}

output "pubsub_subscriptions" {
  description = "Information about created Pub/Sub subscriptions"
  value       = module.pubsub.subscriptions
}

output "pubsub_topic_names" {
  description = "Names of created Pub/Sub topics"
  value       = module.pubsub.topic_names
}

# Cloud Scheduler
output "scheduler_jobs" {
  description = "Information about created Cloud Scheduler jobs"
  value       = module.scheduler.jobs
}

output "scheduler_job_names" {
  description = "Names of created Cloud Scheduler jobs"
  value       = module.scheduler.job_names
}

# Connection Information for Applications
output "database_connections" {
  description = "Database connection information (when applicable)"
  value = {
    # Add database connection info when databases are configured
    # For now, this is a placeholder for future database resources
  }
}

# Environment Variables for Services
output "service_environment_variables" {
  description = "Environment variables that should be set for each service"
  value = {
    backend = {
      GCP_PROJECT_ID     = var.project_id
      GCP_REGION        = var.region
      DATA_BUCKET       = module.storage.bucket_names["comoda_data"]
      MODELS_BUCKET     = module.storage.bucket_names["comoda_models"]
      PUBSUB_TOPICS     = jsonencode(module.pubsub.topic_names)
      SECRET_PREFIX     = "projects/${var.project_id}/secrets"
    }
    frontend = {
      GCP_PROJECT_ID = var.project_id
      GCP_REGION    = var.region
      BACKEND_URL   = module.cloud_run.service_urls["backend"]
    }
    ml = {
      GCP_PROJECT_ID = var.project_id
      GCP_REGION    = var.region
      DATA_BUCKET   = module.storage.bucket_names["comoda_data"]
      MODELS_BUCKET = module.storage.bucket_names["comoda_models"]
      PUBSUB_TOPICS = jsonencode(module.pubsub.topic_names)
      SECRET_PREFIX = "projects/${var.project_id}/secrets"
    }
    backfill = {
      GCP_PROJECT_ID = var.project_id
      GCP_REGION    = var.region
      DATA_BUCKET   = module.storage.bucket_names["comoda_data"]
      PUBSUB_TOPICS = jsonencode(module.pubsub.topic_names)
      SECRET_PREFIX = "projects/${var.project_id}/secrets"
    }
  }
}

# Resource Summary
output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    cloud_run_services    = length(module.cloud_run.services)
    storage_buckets      = length(module.storage.buckets)
    service_accounts     = length(module.iam.service_accounts)
    secrets             = length(module.secrets.secrets)
    pubsub_topics       = length(module.pubsub.topics)
    pubsub_subscriptions = length(module.pubsub.subscriptions)
    scheduler_jobs      = length(module.scheduler.jobs)
  }
}

# Deployment Commands
output "deployment_commands" {
  description = "Useful commands for deploying applications"
  value = {
    docker_build_commands = {
      for service_name in keys(var.cloud_run_services) : service_name => 
      "docker build -t ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.comoda_images.repository_id}/${service_name}:latest ./${service_name}"
    }
    docker_push_commands = {
      for service_name in keys(var.cloud_run_services) : service_name => 
      "docker push ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.comoda_images.repository_id}/${service_name}:latest"
    }
    cloud_run_deploy_commands = {
      for service_name in keys(var.cloud_run_services) : service_name => 
      "gcloud run deploy ${service_name} --image ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.comoda_images.repository_id}/${service_name}:latest --region ${var.region} --platform managed"
    }
  }
}