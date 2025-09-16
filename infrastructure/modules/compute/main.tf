data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  ami_id         = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  alb_subnet_ids = length(var.alb_subnet_ids) > 0 ? var.alb_subnet_ids : var.subnet_ids
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.additional_tags)
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-${var.environment}-alb"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${var.environment}-alb"
  })
}

resource "aws_security_group" "instances" {
  name        = "${var.name_prefix}-${var.environment}-instances"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow HTTP from ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb.id]
  }

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidr
    content {
      description = "Allow SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${var.environment}-instances"
  })
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-${var.environment}-lt-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  user_data     = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  }))

  vpc_security_group_ids = [aws_security_group.instances.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.name_prefix}-${var.environment}-web"
      Role = "web"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "this" {
  name               = "${var.name_prefix}-${var.environment}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.alb_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "blue" {
  name        = "${var.name_prefix}-${var.environment}-blue"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(local.common_tags, {
    Name       = "${var.name_prefix}-${var.environment}-blue"
    Deployment = "blue"
  })
}

resource "aws_lb_target_group" "green" {
  name        = "${var.name_prefix}-${var.environment}-green"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(local.common_tags, {
    Name       = "${var.name_prefix}-${var.environment}-green"
    Deployment = "green"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

resource "aws_autoscaling_group" "blue" {
  name                = "${var.name_prefix}-${var.environment}-blue"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_desired_capacity
  min_size            = var.asg_desired_capacity
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.blue.arn]

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-${var.environment}-blue"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Deployment"
    value               = "blue"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "green" {
  name                = "${var.name_prefix}-${var.environment}-green"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_desired_capacity
  min_size            = var.asg_desired_capacity
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.green.arn]

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-${var.environment}-green"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Deployment"
    value               = "green"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
