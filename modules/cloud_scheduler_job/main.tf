variable "name" { type = string }
variable "schedule" { type = string }
variable "time_zone" { type = string default = "UTC" }
variable "http_target_url" { type = string }
variable "http_method" { type = string default = "POST" }
variable "headers" { type = map(string) default = {} }
variable "body" { type = string default = "" }

resource "google_cloud_scheduler_job" "job" {
  name        = var.name
  schedule    = var.schedule
  time_zone   = var.time_zone

  http_target {
    uri         = var.http_target_url
    http_method = var.http_method
    headers     = var.headers
    body        = length(var.body) > 0 ? base64encode(var.body) : null
  }
}

output "job_name" { value = google_cloud_scheduler_job.job.name }