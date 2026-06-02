output "cluster_name" {
  value = module.eks.cluster_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "eks_cluster_role_name" {
  value = module.eks.cluster_iam_role_name
}

output "eks_cluster_role_arn" {
  value = module.eks.cluster_iam_role_arn
}

output "eks_node_role_name" {
  value = module.eks.node_iam_role_name
}

output "eks_node_role_arn" {
  value = module.eks.node_iam_role_arn
}
