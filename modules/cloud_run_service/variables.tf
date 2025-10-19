variable "name" { type = string }
variable "location" { type = string }
variable "image" { type = string }
variable "env" { type = map(string) default = {} }
variable "cpu" { type = number default = 1 }
variable "memory" { type = string default = "512Mi" }
variable "ingress" { type = string default = "all" }
variable "max_instances" { type = number default = 10 }
variable "service_account" { type = string }
variable "allow_unauthenticated" { type = bool default = true }
