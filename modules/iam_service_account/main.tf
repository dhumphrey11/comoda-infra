variable "name" { type = string }
variable "display_name" { type = string default = null }
variable "roles" { type = list(string) default = [] }
variable "project_id" { type = string }

resource "google_service_account" "sa" {
  account_id   = var.name
  display_name = coalesce(var.display_name, var.name)
}

resource "google_project_iam_member" "bindings" {
  for_each = toset(var.roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa.email}"
}

output "email" { value = google_service_account.sa.email }
output "name" { value = google_service_account.sa.name }