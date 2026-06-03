terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

provider "aws" {
  region = var.region
}