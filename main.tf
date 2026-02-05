# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] # Ubuntu 22.04 LTS
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical owner ID
}

# Security group to allow SSH and Kubernetes traffic
resource "aws_security_group" "k8s_sg" {
  name_prefix = "k8s-sg-"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443 # Kubernetes API server port
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all traffic within the security group (for CNI like Calico)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Single EC2 instance
resource "aws_instance" "k8s_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium" # t3.medium or larger is recommended for a control plane
  key_name      = var.key_pair_name
  user_data     = file("bootstrap.sh")
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "single-kubeadm-node"
  }
}

output "public_ip" {
  value = aws_instance.k8s_node.public_ip
}
