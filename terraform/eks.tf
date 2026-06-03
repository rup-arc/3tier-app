module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name    = "myeks"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  # -------------------------
  # NODE GROUP (STABLE CONFIG)
  # -------------------------
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      labels = {
        role = "general"
      }
    }
  }

  # -------------------------
  # ADDONS
  # -------------------------
  cluster_addons = {
    vpc-cni            = { most_recent = true }
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }

  # -------------------------
  # LOGGING (OPTIONAL BUT GOOD)
  # -------------------------
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator"
  ]

  # -------------------------
  # IRSA (REQUIRED FOR ALB)
  # -------------------------
  enable_irsa = true

  tags = {
    Project = var.project
  }
}