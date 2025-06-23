/*
------------------------------------
Compute Layer: ECS Cluster (EC2 Launch Type)
------------------------------------
*/

/*
Step 1: Create the ECS Cluster control plane.
This is just the logical cluster construct. No compute capacity is provisioned yet.
*/
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name

  tags = var.tags
}

# =======================================================================

/*
------------------------------------
IAM Role for EC2 Instances (EC2 Container Instances)
------------------------------------

We need to create an IAM role that will be attached to the EC2 instances running the ECS agent.

This role allows:
- The ECS agent to register instances to the cluster
- Pull Docker images from ECR
- Write agent-level logs to CloudWatch (host-level logs, not task logs)

This role is ONLY for the EC2 instance itself.
*/

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs_instance_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com"}
    }]
  })
}


/*
Attach AWS-managed policy that includes permissions for:
- ecs:*
- ecr:*
- cloudwatch:*
This policy is called 'AmazonEC2ContainerServiceforEC2Role'
and is designed for EC2 container instances.
*/
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


/*
Create an Instance Profile to attach this IAM Role to EC2 instances.
Instance Profiles wrap IAM roles for EC2 service to consume.
*/
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

# =======================================================================

/*
------------------------------------
Fetch the latest ECS-Optimized AMI from SSM Parameter Store
------------------------------------

Instead of hardcoding AMI IDs, we dynamically fetch the latest recommended ECS-Optimized AMI for Amazon Linux 2.
This ensures our cluster always uses up-to-date ECS-optimized images.
*/

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.ecs_ami.value]
  }
}

# =======================================================================

/*
------------------------------------
Launch Template for Auto Scaling Group
------------------------------------

Defines how EC2 instances will launch, including:
- AMI ID
- Instance type
- IAM Instance Profile
- User data (to bootstrap ECS agent)
*/

resource "aws_key_pair" "ecs_key_pair" {
  key_name   = var.key_pair_name
  public_key = file("bastion-key.pub")  # Path to your existing public key
  
  tags = var.tags
}

resource "aws_security_group" "ecs_instance_sg" {
  name_prefix = "ecs-instance-sg"
  vpc_id      = module.vpc.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this to your IP for better security
  }

  # All outbound traffic (needed for ECS agent, Docker pulls, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}


resource "aws_launch_template" "ecs_launch_template" {
  name_prefix = "ecs-ec2-"
  image_id = data.aws_ami.ecs_ami.id
  instance_type = var.ec2_instance_type

  # Use the created key pair
  key_name = aws_key_pair.ecs_key_pair.key_name


   /*
  Attach the IAM Instance Profile created earlier
  */
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  /*
  User Data bootstrap script:
  This tells the ECS Agent which cluster to register to.
  This is absolutely required for EC2 container instances.
  */
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
  EOF
  )

  vpc_security_group_ids = [aws_security_group.ecs_instance_sg.id]
}

# =======================================================================

/*
------------------------------------
Auto Scaling Group (ASG) for ECS EC2 Instances
------------------------------------

Creates and manages EC2 instances inside private subnets.
Launch Template defines how instances are created.
*/

resource "aws_autoscaling_group" "ecs_asg" {
  name                      = var.asg_name
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = module.vpc.private_subnet_ids

  /*
  Attach Launch Template defined earlier
  */
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
      key                 = "Name"
      value               = "ecs-ec2-instance"
      propagate_at_launch = true # Every EC2 instance created by this ASG should inherit this tag.
    }
}
