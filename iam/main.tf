terraform {
  required_version = ">= 1.6.0"
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
  backend_roles = [
    "roles/run.invoker",
    "roles/run.admin",
    "roles/storage.objectViewer",
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
  ]
  ml_roles = [
    "roles/run.invoker",
    "roles/storage.admin",
    "roles/bigquery.dataEditor",
    "roles/secretmanager.secretAccessor",
  ]
  backfill_roles = [
    "roles/run.invoker",
    "roles/storage.admin",
    "roles/secretmanager.secretAccessor",
    "roles/bigquery.dataEditor",
  ]
  frontend_roles = [
    "roles/run.invoker",
    "roles/storage.objectViewer",
  ]
}

module "sa_backend" {
  source      = "../modules/iam_service_account"
  project_id  = var.project_id
  name        = "comoda-backend-sa"
  display_name = "Comoda Backend SA"
  roles       = local.backend_roles
}

module "sa_ml" {
  source      = "../modules/iam_service_account"
  project_id  = var.project_id
  name        = "comoda-ml-sa"
  display_name = "Comoda ML SA"
  roles       = local.ml_roles
}

module "sa_backfill" {
  source      = "../modules/iam_service_account"
  project_id  = var.project_id
  name        = "comoda-backfill-sa"
  display_name = "Comoda Backfill SA"
  roles       = local.backfill_roles
}

module "sa_frontend" {
  source      = "../modules/iam_service_account"
  project_id  = var.project_id
  name        = "comoda-frontend-sa"
  display_name = "Comoda Frontend SA"
  roles       = local.frontend_roles
}

output "backend_sa_email" { value = module.sa_backend.email }
output "ml_sa_email"      { value = module.sa_ml.email }
output "backfill_sa_email"{ value = module.sa_backfill.email }
output "frontend_sa_email"{ value = module.sa_frontend.email }