provider "aws" {
  region = var.region
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_region" "current" {
}

data "aws_ami_ids" "ami" {
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2017*-gp2"]
  }
}

locals {
  cluster_name = "rabbitmq-${var.name}"
  }

data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "cloud-init" {
  template = file("${path.module}/cloud-init.yaml")

  vars = {
    sync_node_count = 3
    asg_name        = local.cluster_name
    region          = data.aws_region.current.name
    admin_password  = var.admin_password
    rabbit_password = var.rabbit_password
    secret_cookie   = var.secret_cookie
    message_timeout = 3 * 24 * 60 * 60 * 1000 # 3 days
  }
}

resource "aws_iam_role" "role" {
  name               = local.cluster_name
  assume_role_policy = data.aws_iam_policy_document.policy_doc.json
}

resource "aws_iam_role_policy" "policy" {
  name = local.cluster_name
  role = aws_iam_role.role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = local.cluster_name
  role        = aws_iam_role.role.name
}

resource "aws_lb" "test" {
  name               = local.cluster_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0ec0f114225b21ad0"]
  subnets            = var.subnet_ids

  enable_deletion_protection = false # in prod change to true


  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_lb_target_group" "test" {
  name     = local.cluster_name
  port     = 15672
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}




resource "aws_launch_configuration" "rabbitmq" {
  name                 = local.cluster_name
  image_id             = data.aws_ami_ids.ami.ids[0]
  instance_type        = var.instance_type
  key_name             = var.ssh_key_name
  security_groups      = ["sg-0ec0f114225b21ad0"]
  iam_instance_profile = aws_iam_instance_profile.profile.id
  user_data            = data.template_file.cloud-init.rendered

  root_block_device {
    volume_type           = var.instance_volume_type
    volume_size           = var.instance_volume_size
    iops                  = var.instance_volume_iops
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "rabbitmq" {
  name                      = local.cluster_name
  min_size                  = var.min_size
  desired_capacity          = var.desired_size
  max_size                  = var.max_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.rabbitmq.name
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = ["${aws_lb_target_group.test.arn}"]
  tag {
    key                 = "Name"
    value               = local.cluster_name
    propagate_at_launch = true
  }
}



