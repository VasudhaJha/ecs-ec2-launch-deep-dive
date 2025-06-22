variable "region" {
  description = "Region to deploy resources in"
  type = string
  default = "ap-south-1"
}

variable "repo_name" {
  description = "Name of the ECR repository"
  type = string
  default = "ecs-ec2-app"
}

variable "tags" {
  description = "Common tags to be applied to resources"
  type = map
  default = {
    Project = "ecs-ec2-launch-deep-dive"
  }
}