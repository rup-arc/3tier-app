module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  name               = "${var.project}-cluster"
  kubernetes_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  eks_managed_node_groups = {
    main = {
      desired_size   = 1
      min_size       = 1
      max_size       = 1

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Project = var.project
  }
}