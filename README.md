# ECS EC2 Launch Deep Dive

This hands-on project demonstrates how to deploy containerized applications using Amazon Elastic Container Service (ECS) with the EC2 launch type.

## Stack Used

- AWS ECS (EC2 Launch Type)
- AWS ECR
- AWS ALB (Application Load Balancer)
- Docker
- Terraform

## Key Concepts Covered

- ECS Cluster Setup (EC2 Launch Type)
- Task Definitions with `awsvpc` networking mode
- Task Role vs Execution Role (IAM)
- ENIs (Elastic Network Interfaces) for task-level isolation
- Placement Strategies and Placement Constraints
- ALB integration with ECS Services
- Manual scaling & task placement behavior

## Status

Project in active development as part of my AWS DevOps learning journey.

---

Stay tuned for step-by-step walkthroughs and infrastructure diagrams.
