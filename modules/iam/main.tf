# IAM Service Accounts Module
# This module creates service accounts and manages IAM roles for Comoda services

# Local variables for service account configuration
locals {
  service_accounts = {
    backend = {
      account_id   = "comoda-backend"
      display_name = "Comoda Backend Service Account"
      description  = "Service account for the Comoda backend API service"
      roles = [
        "roles/run.invoker",           # Invoke other Cloud Run services
        "roles/secretmanager.secretAccessor", # Access Secret Manager secrets
        "roles/pubsub.editor",         # Publish and subscribe to Pub/Sub topics
        "roles/storage.objectAdmin",   # Read/write access to storage buckets
        "roles/logging.logWriter",     # Write application logs
        "roles/monitoring.metricWriter", # Write custom metrics
        "roles/cloudtrace.agent",      # Write trace data
      ]
    }
    frontend = {
      account_id   = "comoda-frontend"
      display_name = "Comoda Frontend Service Account"
      description  = "Service account for the Comoda frontend web application"
      roles = [
        "roles/run.invoker",           # Invoke backend Cloud Run service
        "roles/logging.logWriter",     # Write application logs
        "roles/monitoring.metricWriter", # Write custom metrics
        "roles/cloudtrace.agent",      # Write trace data
      ]
    }
    ml = {
      account_id   = "comoda-ml"
      display_name = "Comoda ML Service Account"
      description  = "Service account for the Comoda machine learning service"
      roles = [
        "roles/secretmanager.secretAccessor", # Access Secret Manager secrets
        "roles/pubsub.editor",         # Publish and subscribe to Pub/Sub topics
        "roles/storage.objectAdmin",   # Read/write access to storage buckets
        "roles/logging.logWriter",     # Write application logs
        "roles/monitoring.metricWriter", # Write custom metrics
        "roles/cloudtrace.agent",      # Write trace data
        "roles/ml.developer",          # ML platform access
        "roles/aiplatform.user",       # AI Platform access
      ]
    }
    backfill = {
      account_id   = "comoda-backfill"
      display_name = "Comoda Backfill Service Account"
      description  = "Service account for the Comoda data backfill service"
      roles = [
        "roles/secretmanager.secretAccessor", # Access Secret Manager secrets
        "roles/pubsub.editor",         # Publish and subscribe to Pub/Sub topics
        "roles/storage.objectAdmin",   # Read/write access to storage buckets
        "roles/logging.logWriter",     # Write application logs
        "roles/monitoring.metricWriter", # Write custom metrics
        "roles/cloudtrace.agent",      # Write trace data
        "roles/dataflow.developer",    # Dataflow jobs (if using)
      ]
    }
  }
}

# Create service accounts
resource "google_service_account" "service_accounts" {
  for_each = local.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.project_id
}

# Assign IAM roles to service accounts
resource "google_project_iam_member" "service_account_roles" {
  for_each = {
    for pair in flatten([
      for sa_name, sa_config in local.service_accounts : [
        for role in sa_config.roles : {
          sa_name = sa_name
          role    = role
          key     = "${sa_name}_${replace(role, "/", "_")}"
        }
      ]
    ]) : pair.key => pair
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.sa_name].email}"

  depends_on = [google_service_account.service_accounts]
}

# Create service account keys for external access (if needed)
resource "google_service_account_key" "service_account_keys" {
  for_each = var.create_service_account_keys ? local.service_accounts : {}

  service_account_id = google_service_account.service_accounts[each.key].name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Cross-service invocation permissions
# Allow backend to invoke ML and backfill services
resource "google_cloud_run_service_iam_member" "cross_service_invocation" {
  for_each = toset(["ml", "backfill"])

  location = var.region
  project  = var.project_id
  service  = "comoda-${each.value}"
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.service_accounts["backend"].email}"
}

# Custom IAM role for enhanced permissions (if needed)
resource "google_project_iam_custom_role" "comoda_service_role" {
  count = var.create_custom_role ? 1 : 0

  role_id     = "comodaServiceRole"
  title       = "Comoda Service Custom Role"
  description = "Custom role with specific permissions for Comoda services"
  project     = var.project_id

  permissions = [
    "run.services.get",
    "run.services.list",
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update",
    "pubsub.topics.publish",
    "pubsub.subscriptions.consume",
    "secretmanager.versions.access",
    "logging.logEntries.create",
    "monitoring.timeSeries.create",
  ]

  stage = "ALPHA"
}

# Assign custom role to service accounts (if created)
resource "google_project_iam_member" "custom_role_assignment" {
  for_each = var.create_custom_role ? local.service_accounts : {}

  project = var.project_id
  role    = google_project_iam_custom_role.comoda_service_role[0].id
  member  = "serviceAccount:${google_service_account.service_accounts[each.key].email}"

  depends_on = [
    google_service_account.service_accounts,
    google_project_iam_custom_role.comoda_service_role
  ]
}

# Workload Identity bindings (if using GKE)
resource "google_service_account_iam_member" "workload_identity" {
  for_each = var.enable_workload_identity ? local.service_accounts : {}

  service_account_id = google_service_account.service_accounts[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.kubernetes_namespace}/${each.value.account_id}]"
}

# Service account impersonation for deployment (GitHub Actions SA)
resource "google_service_account_iam_member" "github_actions_impersonation" {
  for_each = var.enable_github_actions_impersonation ? local.service_accounts : {}

  service_account_id = google_service_account.service_accounts[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:github-actions@${var.project_id}.iam.gserviceaccount.com"

  depends_on = [google_service_account.service_accounts]
}