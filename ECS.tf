#####################
# CloudWatch Log Group
#####################
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}-task"
  retention_in_days = 14
}

#####################
# ECS CLUSTER
#####################

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
}

#####################
# ECS TASK ROLE & SECRETS PERMISSION
#####################

resource "aws_iam_policy" "ecs_secrets_access" {
  name   = "${var.project_name}-ecs-secrets-access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["secretsmanager:GetSecretValue"],
        Resource = aws_secretsmanager_secret.ci4_db_secret.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attach_secrets" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_secrets_access.arn
}

#####################
# ECS TASK DEFINITION
#####################

resource "aws_ecs_task_definition" "webapp" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "php-web"
      image     = "471546218660.dkr.ecr.eu-west-1.amazonaws.com/php-cs3-framework:latest"
      essential = true
      portMappings = [
        { containerPort = 80 }
      ]
      environment = [
        { name = "AWS_SECRET_ID", value = aws_secretsmanager_secret.ci4_db_secret.name },
        { name = "BASE_URL", value = "http://${data.aws_lb.main.dns_name}" }
        
      ]
      secrets = [
        {
          name      = "DB_CREDENTIALS"
          valueFrom = aws_secretsmanager_secret_version.ci4_db_secret_version.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-task"
          awslogs-region        = "eu-west-1"
          awslogs-stream-prefix = "php-web"
        }
      }
    }
  ])

}


#####################
# ECS SERVICE
#####################

resource "aws_ecs_service" "web_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.webapp.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets          = [
      aws_subnet.public_1a.id,
      aws_subnet.public_1b.id
    ]
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "php-web"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]
}
