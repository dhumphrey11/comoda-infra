variable "secrets" {
  description = "Map of secret name to secret string (first version). Leave empty to create only secret shells."
  type        = map(string)
  default     = {}
}

resource "google_secret_manager_secret" "secrets" {
  for_each  = var.secrets
  secret_id = each.key
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "versions" {
  for_each    = var.secrets
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
}

output "secret_ids" { value = { for k, v in google_secret_manager_secret.secrets : k => v.id } }