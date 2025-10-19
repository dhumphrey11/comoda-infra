output "service_urls" {
  value = {
    backend  = module.backend.url
    ml       = module.ml.url
    backfill = module.backfill.url
  }
}