module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.project}-vpc-2"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  # -------------------------
  # REQUIRED FOR EKS + ALB
  # -------------------------
  public_subnet_tags = {
    "kubernetes.io/role/elb"                   = "1"
    "kubernetes.io/cluster/${var.project}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"          = "1"
    "kubernetes.io/cluster/${var.project}-eks" = "shared"
  }

  tags = {
    Project = var.project
  }
}