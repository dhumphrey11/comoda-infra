# Cloud Run Module Outputs

output "services" {
  description = "Information about all Cloud Run services"
  value = {
    for name, service in google_cloud_run_v2_service.services : name => {
      name     = service.name
      location = service.location
      uri      = service.uri
      status   = service.status
    }
  }
}

output "service_urls" {
  description = "URLs of all Cloud Run services"
  value = {
    for name, service in google_cloud_run_v2_service.services : name => service.uri
  }
}

output "service_names" {
  description = "Names of all Cloud Run services"
  value = {
    for name, service in google_cloud_run_v2_service.services : name => service.name
  }
}