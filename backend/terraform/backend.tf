terraform {
  backend "s3" {
    bucket  = "rupam-3tier-tfstate-2026"
    key     = "infra/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}