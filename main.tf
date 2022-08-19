terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_instance" "remote_builder" {
  ami             = data.aws_ami.amazon-2.id
  instance_type   = "c5.large"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.allow_team_access.name]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.public_ip
    private_key = file("~/.ssh/key.pub")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo chkconfig docker on"
    ]
  }
}

resource "aws_security_group" "allow_team_access" {
  name        = "allow_team_access"
  description = "Allows access from approved ip addresses where the team is working from"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "All communication from specific IP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${chomp(data.http.icanhazip.response_body)}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_vpc" "selected" {
  id = "vpc-87d821ee"
}

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/key.pub")
}

output "public_ip" {
  value = aws_instance.remote_builder.public_ip
}

output "remote_docker_var" {
  value = "export DOCKER_HOST=ssh://ec2-user@${aws_instance.remote_builder.public_ip}"
}
