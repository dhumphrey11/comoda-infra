variable "name" { type = string }

resource "google_pubsub_topic" "topic" {
  name = var.name
}

output "topic" { value = google_pubsub_topic.topic.name }