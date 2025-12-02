#####################
# ECS CLUSTER
#####################

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
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
      image = "471546218660.dkr.ecr.eu-west-1.amazonaws.com/php-cs3-framework:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
        }
      ]
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
