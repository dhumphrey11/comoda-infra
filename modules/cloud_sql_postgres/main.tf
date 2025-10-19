variable "name" { type = string }
variable "region" { type = string }
variable "tier" { type = string default = "db-custom-1-3840" }
variable "databases" { type = list(string) }
variable "users" {
  type = list(object({ name = string, password = string }))
}

resource "google_sql_database_instance" "postgres" {
  name             = var.name
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.tier
    ip_configuration { ipv4_enabled = true }
    availability_type = "ZONAL"
  }
}

resource "google_sql_database" "dbs" {
  for_each = toset(var.databases)
  name     = each.value
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "users" {
  for_each = { for u in var.users : u.name => u.password }
  name     = each.key
  instance = google_sql_database_instance.postgres.name
  password = each.value
}

output "connection_name" { value = google_sql_database_instance.postgres.connection_name }
output "instance_connection_name" { value = google_sql_database_instance.postgres.connection_name }