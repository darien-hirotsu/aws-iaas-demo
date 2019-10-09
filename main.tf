# AWS provider. Terrform will download the provider code to a .terraform directory.
provider "aws" {
  region = "us-west-1"
}

# AWS autoscaling group.
resource "aws_launch_configuration" "hello_world" {
  image_id        = "ami-0dd655843c87b6930"
  instance_type   = "t2.micro"
  /* Terraform reference (type of Terraform expression) to reference and attach
  the appropriate security group from Terraform code. */
  security_groups = [aws_security_group.web_access.id]
  /* Write a string to index.html as a quick  and dirty way to spin up an app.
  Uses nohup to keep the service running after the script ends. Runs as a
  a background process using the busybox web service. */
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World. It's Terraform time!" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  /* AWS autoscaling. The default is to delete a new resource then create new.
  This setting creates the new instance then destroys the original. */
  lifecycle {
    create_before_destroy = true
  }
}

# AWS security group allowing all source IP addresses to port 8080 (TCP).
resource "aws_security_group" "web_access" {
  name = "web_access"
  ingress {
    # server_port is a Terraform variable whose value is determined at runtime.
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_access" {
  name = "elb_access"
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "scale_hello" {
  launch_configuration = aws_launch_configuration.hello_world.id
  availability_zones   = data.aws_availability_zones.all.names
  min_size = 3
  max_size = 5

  # Attach the AWS CLB to the autoscaling group.
  load_balancers    = [aws_elb.hello-world-elb.name]
  # AWS ELB health check is more robust and monitors more than just hypervisor.
  health_check_type = "ELB"

  # AWS tag assigned to instance.
  tag {
    key                 = "Name"
    value               = "terraform-asg-hello-world"
    propagate_at_launch = true
  }
}

resource "aws_elb" "hello-world-elb" {
  name               = "terraform-hello-world-elb"
  security_groups    = [aws_security_group.elb_access.id]
  availability_zones = data.aws_availability_zones.all.names

  /* AWS classic load balancer health check initated every 30 seconds. The web
  server must respond with a 200 OK. */
  health_check {
    # Terreform uses ${} within a string literal for interpolation.
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }


  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

/* Variables allow for code reuse at runtime. Variables can be declared during
the `terraform apply` via either query or passed as arguments. */
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

/* Data sources contain information required for configuration. They are read-only
and retrieved from the provider's API. */
data "aws_availability_zones" "all" {}

/* Terraform allows for creating output variables to store data. You can use
a sensitive boolean to not log sensitive information after an apply. */
output "elb_dns_name" {
  value       = aws_elb.hello-world-elb.dns_name
  description = "The domain name of the elb load balancer"
}
