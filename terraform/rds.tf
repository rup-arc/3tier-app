resource "aws_db_subnet_group" "db" {
  name       = "threetierappdbsubnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "rds" {
  name   = "threetierapp-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "rds-threetierapp"

  engine         = "postgres"
  engine_version = "15"

  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_name  = "appdb"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Project = "threetierapp"
  }
}