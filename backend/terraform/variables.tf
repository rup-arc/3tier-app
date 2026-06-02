variable "region" {
  default = "ap-south-1"
}

variable "project" {
  default = "3tier-app"
}

variable "db_password" {
  type      = string
  sensitive = true
}