variable "project_id" { type = string }
variable "region" { type = string }
variable "location" { type = string }
variable "model_bucket" { type = string default = "comoda-models" }
variable "backfill_bucket" { type = string default = "comoda-backfill" }
variable "artifacts_bucket" { type = string default = "comoda-artifacts" }