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
    project = "ecs-ec2-launch-deep-dive"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "custom-vpc"
}

variable "num_private_subnets" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "num_public_subnets" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
  default     = "ecs-ec2-cluster"
}

variable "ec2_instance_type" {
  description = "Type of EC2 instance to be provisioned"
  type        = string
  default     = "t3.medium"
}

variable "asg_name" {
  description = "Name of the ASG"
  type        = string
  default = "ecs-ec2-asg"
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
  default = "bastion-key"
}

variable "task_family_name" {
  default = "ecs-ec2-task"
}

variable "task_cpu" {
  default = 512
}

variable "task_memory" {
  default = 256
}

variable "ecr_repo_url" {
  default = "541659175825.dkr.ecr.ap-south-1.amazonaws.com/ecs-ec2-app"
}

variable "image_tag" {
  default = "5851a6c208153c4b1500c682364fbc9464bb26d2"
}

variable "log_group_name" {
  default = "/ecs/ecs-ec2-app"
}

variable "container_port" {
  default = 9099
}

variable "container_name" {
  default = "ecs-ec2-app"
}

variable "service_name" {
  default = "ecs-ec2-service"
}

variable "desired_count" {
  default = 2
}

variable "alb_name" {
  default = "ecs-app-alb"
}

variable "alb_tg_name" {
  default = "ecs-app-tg"
}