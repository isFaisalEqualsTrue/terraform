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

# Retrieve the subnet(s) associated with the default VPC
data "aws_subnet" "subnets" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-2a"
}

# Create an AWS Auto Scaling Group for the web instances
resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = [data.aws_subnet.subnets.id]
  min_size             = 2                                
  max_size             = 10                               

  tag {
    key                 = "Name"                
    value               = "web_asg"             
    propagate_at_launch = true
  }
}

