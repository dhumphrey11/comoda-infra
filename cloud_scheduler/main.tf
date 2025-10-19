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
}

module "ingestion" {
  source          = "../modules/cloud_scheduler_job"
  name            = "comoda-ingestion-cron"
  schedule        = "*/15 * * * *" # every 15 minutes
  http_target_url = "${var.backend_url}/tasks/ingest"
  http_method     = "POST"
}

module "ml_retrain" {
  source          = "../modules/cloud_scheduler_job"
  name            = "comoda-ml-retrain-cron"
  schedule        = "0 3 * * 1" # 03:00 UTC Mondays
  http_target_url = "${var.ml_url}/tasks/retrain"
  http_method     = "POST"
}

module "ml_scoring" {
  source          = "../modules/cloud_scheduler_job"
  name            = "comoda-ml-scoring-cron"
  schedule        = "*/10 * * * *" # every 10 minutes
  http_target_url = "${var.ml_url}/tasks/score"
  http_method     = "POST"
}

module "backfill" {
  source          = "../modules/cloud_scheduler_job"
  name            = "comoda-backfill-cron"
  schedule        = "0 */6 * * *" # every 6 hours
  http_target_url = "${var.backfill_url}/tasks/backfill"
  http_method     = "POST"
}

output "jobs" {
  value = {
    ingestion = module.ingestion.job_name
    retrain   = module.ml_retrain.job_name
    scoring   = module.ml_scoring.job_name
    backfill  = module.backfill.job_name
  }
}