variable "project_id" { type = string }
variable "region" { type = string }
variable "location" { type = string }
variable "instance_name" { type = string default = "comoda-postgres" }
variable "db_tier" { type = string default = "db-custom-2-7680" }
variable "databases" {
  type    = list(string)
  default = ["portfolio", "metrics", "signals"]
}
variable "db_user" { type = string default = "app" }
variable "db_password" { type = string default = "change_me" }