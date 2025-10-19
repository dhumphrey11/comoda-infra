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

module "postgres" {
  source    = "../modules/cloud_sql_postgres"
  name      = var.instance_name
  region    = var.region
  tier      = var.db_tier
  databases = var.databases
  users     = [{ name = var.db_user, password = var.db_password }]
}

output "connection_name" { value = module.postgres.connection_name }