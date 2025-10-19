output "buckets" {
  value = {
    models    = module.models.bucket_name
    backfill  = module.backfill.bucket_name
    artifacts = module.artifacts.bucket_name
  }
}