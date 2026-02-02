// Application Load Balancer, target groups, listener and security group

resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.project_name}-alb-sg-"
  description = "Security group for ALB allowing HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default_public.ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

locals {
  alb_ports = [8081, 8082, 8083]
}

resource "aws_lb_target_group" "app_tg" {
  for_each = { for p in local.alb_ports : tostring(p) => p }

  name        = "${var.project_name}-tg-${each.key}"
  port        = each.value
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.default.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    path                = "/"
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg-${each.key}"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "Page not found"
      status_code  = "404"
    }
  }
}

// Path-based listener rules: /app1 -> 8081, /app2 -> 8082, /app3 -> 8083
resource "aws_lb_listener_rule" "app_paths" {
  for_each = {
    app1 = {
      path     = "/app1/*"
      tg_port  = "8081"
      priority = 100
    }
    app2 = {
      path     = "/app2/*"
      tg_port  = "8082"
      priority = 200
    }
    app3 = {
      path     = "/app3/*"
      tg_port  = "8083"
      priority = 300
    }
  }

  listener_arn = aws_lb_listener.http_listener.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[each.value.tg_port].arn
  }

  condition {
    path_pattern {
      values = [each.value.path]
    }
  }
}

// Attach the existing EC2 instance to each target group
resource "aws_lb_target_group_attachment" "app_attachments" {
  for_each = { for p in local.alb_ports : tostring(p) => p }

  target_group_arn = aws_lb_target_group.app_tg[each.key].arn
  target_id        = aws_instance.app_server.id
  port             = each.value
}
