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

module "analytics" {
  source      = "../modules/bigquery_dataset"
  dataset_id  = var.analytics_dataset
  location    = var.location
  description = "Comoda analytics and model metrics dataset"
}

output "dataset_id" { value = module.analytics.dataset_id }
