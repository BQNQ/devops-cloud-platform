resource "aws_db_subnet_group" "main" {
  name       = "postgres-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Env = terraform.workspace
  }
}

resource "aws_security_group" "postgres" {
  name   = "postgres-sg"
  vpc_id = var.vpc_id

  tags = {
    Env = terraform.workspace
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id = aws_security_group.postgres.id
  cidr_ipv4         = "10.0.0.0/16"

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"

  tags = {
    Env = terraform.workspace
  }
}

resource "aws_db_instance" "postgres" {
  identifier     = terraform.workspace == "dev" ? "postgres-db-dev" : "postgres-db"
  db_name        = "flaskAppDB"
  engine         = "postgres"
  engine_version = "18"

  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  publicly_accessible = false

  skip_final_snapshot = true

  tags = {
    Env = terraform.workspace
  }
}
