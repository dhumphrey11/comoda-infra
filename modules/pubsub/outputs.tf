# Pub/Sub Module Outputs

output "topics" {
  description = "Information about created Pub/Sub topics"
  value = {
    for name, topic in google_pubsub_topic.topics : name => {
      name = topic.name
      id   = topic.id
    }
  }
}

output "subscriptions" {
  description = "Information about created Pub/Sub subscriptions"
  value = {
    for name, subscription in google_pubsub_subscription.subscriptions : name => {
      name  = subscription.name
      id    = subscription.id
      topic = subscription.topic
    }
  }
}

output "topic_names" {
  description = "Names of created Pub/Sub topics"
  value = {
    for name, topic in google_pubsub_topic.topics : name => topic.name
  }
}

output "subscription_names" {
  description = "Names of created Pub/Sub subscriptions"
  value = {
    for name, subscription in google_pubsub_subscription.subscriptions : name => subscription.name
  }
}