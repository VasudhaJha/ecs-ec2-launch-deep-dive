/*
IAM Layer: Task Role, Execution Role, Instance Role
*/

/*
------------------------------------
IAM Role for ECS Task Execution Role
------------------------------------

This role allows the ECS control plane (not your EC2 instances) to:
- Pull Docker images from ECR
- Write logs to CloudWatch Logs
- Retrieve secrets from AWS Secrets Manager (optional)
*/

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

/*
Attach AWS-managed policy that gives:
- Access to pull ECR images
- Write logs to CloudWatch
- Access Secrets Manager (optional)
*/
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

/*
------------------------------------
IAM Role for ECS Task Role (Application Role)
------------------------------------

This role will be assumed by your container at runtime.
It allows your app to call AWS APIs using temporary credentials.
*/

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

/*
- Right now, we won't attach any permissions yet.
- This keeps it fully secure, principle of least privilege.
- When your app needs AWS access (e.g. read S3, fetch Secrets), you'll attach policies here.
*/

