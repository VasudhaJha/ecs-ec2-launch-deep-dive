/*
Container Layer: ECS Task Definition, ECS Service
*/


/*
------------------------------------
CloudWatch Log Group for ECS Tasks
------------------------------------

This log group must exist before ECS tasks can write logs to it.
*/

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.cluster_name}/${var.service_name}"
  retention_in_days = 1

  tags = var.tags
  
}


/*
------------------------------------
ECS Task Definition
------------------------------------

This defines how your Dockerized application will run inside ECS.

Field	                Purpose

family	                Logical name of your Task Definition

network_mode	        awsvpc → Each task gets its own ENI and IP

execution_role_arn	    Allow ECS to pull image & write logs

task_role_arn	        Allow app inside container to access AWS APIs

container_definitions	Your Docker image, port mappings, log config
*/

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = var.task_family_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${var.ecr_repo_url}:${var.image_tag}"  # Image pulled from ECR with immutable tag
      essential = true # If this container crashes, stop the entire task

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.cluster_name}/${var.service_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  depends_on = [aws_cloudwatch_log_group.ecs_log_group]
}



/*
------------------------------------
ECS Service: Manages running tasks
------------------------------------

Field	                            Meaning

cluster	                            Which ECS cluster to run inside
task_definition	                    The container blueprint you defined earlier
launch_type = EC2	                Tells scheduler: “place tasks on EC2 instances”
desired_count	                    How many tasks you want running
network_configuration	            Which subnets + security groups tasks use
load_balancer	                    Links this service to ALB Target Group
deployment_minimum_healthy_percent	Rolling deployment behavior
*/

resource "aws_ecs_service" "ecs_service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = "EC2"
  desired_count   = var.desired_count

  network_configuration {
    subnets         = module.vpc.private_subnet_ids
    security_groups = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_lb_listener.alb_listener]
}


resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow ALB to reach container"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # ALB Security Group ID
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
# aws_ecs_service.ecs_service will be created
  + resource "aws_ecs_service" "ecs_service" {
      + availability_zone_rebalancing      = "DISABLED"
      + cluster                            = "arn:aws:ecs:ap-south-1:541659175825:cluster/ecs-ec2-cluster"
      + deployment_maximum_percent         = 200
      + deployment_minimum_healthy_percent = 50
      + desired_count                      = 2
      + enable_ecs_managed_tags            = false
      + enable_execute_command             = false
      + iam_role                           = (known after apply)
      + id                                 = (known after apply)
      + launch_type                        = "EC2"
      + name                               = "ecs-ec2-service"
      + platform_version                   = (known after apply)
      + scheduling_strategy                = "REPLICA"
      + tags_all                           = (known after apply)
      + task_definition                    = (known after apply)
      + triggers                           = (known after apply)
      + wait_for_steady_state              = false

      + load_balancer {
          + container_name   = "ecs-ec2-app"
          + container_port   = 9099
          + target_group_arn = (known after apply)
            # (1 unchanged attribute hidden)
        }

      + network_configuration {
          + assign_public_ip = false
          + security_groups  = (known after apply)
          + subnets          = [
              + "subnet-07e5b1c5cca676ccb",
              + "subnet-0e9633ff1eb73bd97",
            ]
        }
    }
*/
