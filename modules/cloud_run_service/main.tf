resource "google_cloud_run_v2_service" "service" {
  name     = var.name
  location = var.location

  template {
    containers {
      image = var.image
      resources {
        cpu_idle = true
        limits = {
          cpu    = tostring(var.cpu)
          memory = var.memory
        }
      }
      env = [for k, v in var.env : { name = k, value = v }]
    }
    service_account = var.service_account
    scaling {
      max_instance_count = var.max_instances
    }
  }

  ingress = var.ingress
}

resource "google_cloud_run_service_iam_member" "invoker" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = google_cloud_run_v2_service.service.location
  project  = google_cloud_run_v2_service.service.project
  service  = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "url" {
  value = google_cloud_run_v2_service.service.uri
}
output "name" { value = google_cloud_run_v2_service.service.name }