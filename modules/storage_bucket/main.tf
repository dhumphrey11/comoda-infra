variable "name" { type = string }
variable "location" { type = string }
variable "versioning" { type = bool default = true }
variable "lifecycle_days" { type = number default = 0 }

resource "google_storage_bucket" "bucket" {
  name                        = var.name
  location                    = var.location
  uniform_bucket_level_access = true

  versioning {
    enabled = var.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_days > 0 ? [1] : []
    content {
      condition { age = var.lifecycle_days }
      action { type = "Delete" }
    }
  }
}

output "bucket_name" { value = google_storage_bucket.bucket.name }