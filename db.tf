##########################
# DATABASE / RDS CONFIG
##########################

# Genereer automatisch een sterk wachtwoord
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Subnet group voor RDS
resource "aws_db_subnet_group" "ci4_db_subnets" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_db.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Security group voor RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow ECS and test IP access to DB"
  vpc_id      = aws_vpc.main.id

  # ECS toegang
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service_sg.id]
  }

  # Optioneel: jouw IP voor testen
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["<YOUR_PUBLIC_IP>/32"] # vervang door je IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS instance
resource "aws_db_instance" "ci4_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "ci4_database"
  username             = var.db_user
  password             = random_password.db_password.result
  publicly_accessible  = false
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.ci4_db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# Secrets Manager voor ECS en veilige opslag
resource "aws_secretsmanager_secret" "ci4_db_secret" {
  name        = "${var.project_name}-db-credentials"
  description = "Database credentials for CI4 app"
}

resource "aws_secretsmanager_secret_version" "ci4_db_secret_version" {
  secret_id     = aws_secretsmanager_secret.ci4_db_secret.id
  secret_string = jsonencode({
    username = var.db_user
    password = random_password.db_password.result
    database = aws_db_instance.ci4_db.name
    host     = aws_db_instance.ci4_db.address
  })
}
