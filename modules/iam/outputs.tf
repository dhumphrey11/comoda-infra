# IAM Module Outputs

output "service_accounts" {
  description = "Information about created service accounts"
  value = {
    for name, sa in google_service_account.service_accounts : name => {
      name         = sa.name
      email        = sa.email
      unique_id    = sa.unique_id
      account_id   = sa.account_id
      display_name = sa.display_name
    }
  }
}

output "service_account_emails" {
  description = "Email addresses of created service accounts"
  value = {
    for name, sa in google_service_account.service_accounts : name => sa.email
  }
}

output "service_account_keys" {
  description = "Service account keys (if created)"
  value = {
    for name, key in google_service_account_key.service_account_keys : name => {
      name         = key.name
      key_id       = key.key_id
      private_key  = key.private_key
      public_key   = key.public_key
    }
  }
  sensitive = true
}

output "custom_role_id" {
  description = "ID of the custom IAM role (if created)"
  value       = var.create_custom_role ? google_project_iam_custom_role.comoda_service_role[0].id : null
}