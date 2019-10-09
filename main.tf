# AWS provider. Terrform will download the provider code to .terraform directory.
provider "aws" {
  region = "us-west-1"
}

resource "aws_instance" "hello_world" {
  # AWS AMI for Ubuntu 18.04 LTS for us-west-1 region.
  ami           = "ami-0dd655843c87b6930"
  instance_type = "t2.micro"

  /* Terraform reference (type of Terraform expression) to reference and attach
  the appropriate security group from Terraform code. */
  vpc_security_group_ids = [aws_security_group.web_ingress.id]

  /* Write a string to index.html as a quick  and dirty way to spin up an app.
  Uses nohup to keep the service running after the script ends. Runs as a
  a background process using the busybox web service. */
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World. It's TerraForm!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  # AWS EC2 instance name.
  tags = {
    Name = "hello_world"
  }
}

# AWS security group allowing all source IP addresses to port 8080 (TCP).
resource "aws_security_group" "web_ingress" {
  name = "web_ingress"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
