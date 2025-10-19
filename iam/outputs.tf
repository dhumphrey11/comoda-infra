output "service_accounts" {
  value = {
    backend  = module.sa_backend.email
    ml       = module.sa_ml.email
    backfill = module.sa_backfill.email
  }
}

output "frontend_sa_email" {
  value = module.sa_frontend.email
}