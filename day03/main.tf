# Configure the AWS provider with the desired region
provider "aws" {
  region = "us-east-2"
}

# Define a variable for the web server port
variable "web_server_port" {
  description = "The HTTP port"
  type        = number
  default     = 80
}

# Create an AWS security group for the web server
resource "aws_security_group" "web_sg" {
  name = "web_sg"

  ingress {
    from_port   = var.web_server_port
    to_port     = var.web_server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an AWS launch configuration for the Auto Scaling Group
resource "aws_launch_configuration" "example" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.web_server_port} &
  EOF
}

# Retrieve the default AWS VPC for the region
data "aws_vpc" "default" {
  default = true
}

# Retrieve the subnets associated with the default VPC
data "aws_subnet" "subnets" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-2a"
}

data "aws_subnet" "subnets1" {
    vpc_id            = data.aws_vpc.default.id
    availability_zone = "us-east-2b"
  }


# Creating an Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "lb01"
  load_balancer_type = "application"

subnets = [
    data.aws_subnet.subnets.id,
    data.aws_subnet.subnets1.id
  ]

  security_groups = [aws_security_group.lb_sg.id]
}

# Creating a listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# Creating a security group for the load balancer
resource "aws_security_group" "lb_sg" {
  name = "lb_sg01"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Creating a target group
resource "aws_lb_target_group" "my_tg" {
  name     = "mytg01"
  port     = var.web_server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path               = "/"
    protocol           = "HTTP"
    matcher            = "200"
    interval           = 15
    timeout            = 3
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }
}

# Create an AWS Auto Scaling Group for the web instances
resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = [data.aws_subnet.subnets.id]
  target_group_arns    = [aws_lb_target_group.my_tg.arn]
  health_check_type    = "ELB"
  min_size             = 2
  max_size             = 10

  tag {
    key                 = "Name"
    value               = "web_asg"
    propagate_at_launch = true
  }
}

resource "aws_lb_listener_rule" "my_rules" {
   listener_arn = aws_lb_listener.http.arn
   priority     = 1

  condition {
    path_pattern {
      values = ["*"]
    }
  }


   action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.my_tg.arn
          }  
}

output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name
}


