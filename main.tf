# Comoda Infrastructure
# This file configures the core GCP infrastructure for the Comoda application
# including Cloud Run services, storage, messaging, and security resources.

terraform {
  required_version = ">= 1.5"
  
  # Configure remote state storage in Cloud Storage bucket
  # Uncomment and configure the backend after creating the state bucket
  # backend "gcs" {
  #   bucket = "comoda-terraform-state"
  #   prefix = "terraform/state"
  # }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Configure the Google Cloud Beta Provider for beta features
provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs for the project
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",           # Cloud Run
    "storage.googleapis.com",       # Cloud Storage
    "secretmanager.googleapis.com", # Secret Manager
    "pubsub.googleapis.com",       # Pub/Sub
    "cloudscheduler.googleapis.com", # Cloud Scheduler
    "iam.googleapis.com",          # IAM
    "artifactregistry.googleapis.com", # Artifact Registry
    "cloudbuild.googleapis.com",   # Cloud Build
  ])

  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Data source to get project information
data "google_project" "project" {
  project_id = var.project_id
}

# Create Artifact Registry repository for container images
resource "google_artifact_registry_repository" "comoda_images" {
  location      = var.region
  repository_id = "comoda-images"
  description   = "Container images for Comoda services"
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis]
}

# Cloud Storage buckets
module "storage" {
  source = "./modules/storage"
  
  project_id = var.project_id
  region     = var.region
  
  depends_on = [google_project_service.required_apis]
}

# IAM Service Accounts
module "iam" {
  source = "./modules/iam"
  
  project_id = var.project_id
  
  depends_on = [google_project_service.required_apis]
}

# Secret Manager secrets
module "secrets" {
  source = "./modules/secrets"
  
  project_id = var.project_id
  
  depends_on = [google_project_service.required_apis]
}

# Pub/Sub topics and subscriptions
module "pubsub" {
  source = "./modules/pubsub"
  
  project_id = var.project_id
  
  depends_on = [google_project_service.required_apis]
}

# Cloud Scheduler jobs
module "scheduler" {
  source = "./modules/scheduler"
  
  project_id    = var.project_id
  region        = var.region
  pubsub_topics = module.pubsub.topic_names
  
  depends_on = [
    google_project_service.required_apis,
    module.pubsub
  ]
}

# Cloud Run services
module "cloud_run" {
  source = "./modules/cloud_run"
  
  project_id           = var.project_id
  region               = var.region
  artifact_registry_url = google_artifact_registry_repository.comoda_images.repository_id
  service_accounts     = module.iam.service_accounts
  
  # Environment variables from other modules
  storage_buckets = module.storage.bucket_names
  secret_ids      = module.secrets.secret_ids
  pubsub_topics   = module.pubsub.topic_names
  
  depends_on = [
    google_project_service.required_apis,
    google_artifact_registry_repository.comoda_images,
    module.iam,
    module.storage,
    module.secrets,
    module.pubsub
  ]
}