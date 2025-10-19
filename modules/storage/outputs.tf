# Storage Module Outputs

output "buckets" {
  description = "Information about created storage buckets"
  value = {
    for name, bucket in google_storage_bucket.buckets : name => {
      name          = bucket.name
      location      = bucket.location
      storage_class = bucket.storage_class
      url           = "gs://${bucket.name}"
      self_link     = bucket.self_link
    }
  }
}

output "bucket_names" {
  description = "Names of created storage buckets"
  value = {
    for name, bucket in google_storage_bucket.buckets : name => bucket.name
  }
}

output "bucket_urls" {
  description = "URLs of created storage buckets"
  value = {
    for name, bucket in google_storage_bucket.buckets : name => "gs://${bucket.name}"
  }
}