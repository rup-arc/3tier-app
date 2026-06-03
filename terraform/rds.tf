# -----------------------------
# DB SUBNET GROUP
# -----------------------------
resource "aws_db_subnet_group" "db" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Project = var.project
  }
}

# -----------------------------
# SECURITY GROUP FOR RDS
# -----------------------------
resource "aws_security_group" "rds" {
  name   = "rds-${var.project}"
  vpc_id = module.vpc.vpc_id

  # Allow ONLY EKS cluster to access PostgreSQL
  ingress {
    description     = "PostgreSQL from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  # Outbound (required for updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project
  }
}

# -----------------------------
# RDS POSTGRES INSTANCE
# -----------------------------
resource "aws_db_instance" "postgres" {
  identifier = "postgres-${var.project}"

  engine         = "postgres"
  engine_version = "15"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "appdb"
  username = "postgres"
  password = var.db_password

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false

  # Production-safe settings
  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true
  multi_az                = false

  # Performance
  auto_minor_version_upgrade = true

  tags = {
    Project = var.project
  }
}