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

module "models" {
  source    = "../modules/storage_bucket"
  name      = var.model_bucket
  location  = var.location
  versioning = true
}

module "backfill" {
  source    = "../modules/storage_bucket"
  name      = var.backfill_bucket
  location  = var.location
  versioning = true
}

module "artifacts" {
  source    = "../modules/storage_bucket"
  name      = var.artifacts_bucket
  location  = var.location
  versioning = true
}

output "buckets" {
  value = {
    models    = module.models.bucket_name
    backfill  = module.backfill.bucket_name
    artifacts = module.artifacts.bucket_name
  }
}