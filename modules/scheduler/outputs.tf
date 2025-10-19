# Cloud Scheduler Module Outputs

output "jobs" {
  description = "Information about created Cloud Scheduler jobs"
  value = {
    for name, job in google_cloud_scheduler_job.scheduler_jobs : name => {
      name        = job.name
      id          = job.id
      schedule    = job.schedule
      time_zone   = job.time_zone
      description = job.description
    }
  }
}

output "job_names" {
  description = "Names of created Cloud Scheduler jobs"
  value = {
    for name, job in google_cloud_scheduler_job.scheduler_jobs : name => job.name
  }
}

output "http_jobs" {
  description = "Information about HTTP target scheduler jobs (if enabled)"
  value = var.enable_http_jobs ? {
    for name, job in google_cloud_scheduler_job.http_jobs : name => {
      name        = job.name
      id          = job.id
      schedule    = job.schedule
      time_zone   = job.time_zone
      description = job.description
    }
  } : {}
}

output "scheduler_service_account" {
  description = "Scheduler service account information (if created)"
  value = var.create_scheduler_service_account ? {
    email = google_service_account.scheduler_sa[0].email
    name  = google_service_account.scheduler_sa[0].name
  } : null
}