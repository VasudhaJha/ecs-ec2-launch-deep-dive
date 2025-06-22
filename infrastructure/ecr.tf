resource "aws_ecr_repository" "ecs_ec2_app" {
  name = var.repo_name
  image_scanning_configuration {
    scan_on_push = true
  }
  image_tag_mutability = "IMMUTABLE"
  tags = var.tags
}