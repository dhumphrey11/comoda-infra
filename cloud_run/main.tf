terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.39"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  common_env = {
    GCP_PROJECT_ID = var.project_id
    BQ_DATASET     = var.bq_dataset
    GCS_BUCKET     = var.gcs_model_bucket
  }
}

module "backend" {
  source              = "../modules/cloud_run_service"
  name                = "comoda-backend"
  location            = var.region
  image               = var.backend_image
  env                 = local.common_env
  cpu                 = 1
  memory              = "1Gi"
  max_instances       = 10
  service_account     = var.backend_sa_email
  allow_unauthenticated = true
}

module "ml" {
  source              = "../modules/cloud_run_service"
  name                = "comoda-ml"
  location            = var.region
  image               = var.ml_image
  env                 = local.common_env
  cpu                 = 2
  memory              = "2Gi"
  max_instances       = 5
  service_account     = var.ml_sa_email
  allow_unauthenticated = true
}

module "backfill" {
  source              = "../modules/cloud_run_service"
  name                = "comoda-backfill"
  location            = var.region
  image               = var.backfill_image
  env                 = local.common_env
  cpu                 = 1
  memory              = "1Gi"
  max_instances       = 2
  service_account     = var.backfill_sa_email
  allow_unauthenticated = false
}

module "frontend" {
  source              = "../modules/cloud_run_service"
  name                = "comoda-frontend"
  location            = var.region
  image               = var.frontend_image
  env                 = merge(local.common_env, { VITE_API_URL = module.backend.url })
  cpu                 = 1
  memory              = "512Mi"
  max_instances       = 5
  service_account     = var.frontend_sa_email
  allow_unauthenticated = true
}

output "service_urls" {
  value = {
    backend  = module.backend.url
    ml       = module.ml.url
    backfill = module.backfill.url
    frontend = module.frontend.url
  }
}