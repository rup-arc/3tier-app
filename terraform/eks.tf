module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"


  name               = "${var.project}-cluster"
  kubernetes_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  fargate_profiles = {
    default = {
      name           = "default"
      selectors      = [{ namespace = "default" }, { namespace = "kube-system" }]
    }
  }

  tags = {
    Project = var.project
  }
}