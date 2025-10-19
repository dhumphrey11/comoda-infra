variable "dataset_id" { type = string }
variable "location" { type = string }
variable "description" { type = string default = "" }

resource "google_bigquery_dataset" "dataset" {
  dataset_id                 = var.dataset_id
  location                   = var.location
  description                = var.description
  delete_contents_on_destroy = false
}

output "dataset_id" { value = google_bigquery_dataset.dataset.dataset_id }