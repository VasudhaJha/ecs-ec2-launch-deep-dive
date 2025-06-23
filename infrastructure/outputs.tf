output "ecr_repository_url" {
  value = aws_ecr_repository.ecs_ec2_app.repository_url
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.ecs_task.arn
}