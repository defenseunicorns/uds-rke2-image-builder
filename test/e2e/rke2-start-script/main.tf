provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
  }
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_subnet" "test_subnet" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-west-2a"

}

resource "aws_network_interface" "test_node_nic" {
  subnet_id   = data.aws_subnet.test_subnet.id
  security_groups = [aws_security_group.test_node_sg.id]

}

resource "aws_instance" "test_node" {
  ami           = var.ami_id
  instance_type = "m5.2xlarge"
  key_name      = var.ssh_key_name
  user_data = templatefile("${path.module}/scripts/user_data.sh", { BOOTSTRAP_IP = var.bootstrap_ip, AGENT_NODE = var.agent_node, RKE2_JOIN_TOKEN = "example_join_token", DEFAULT_USER = var.default_user })

  network_interface {
    network_interface_id = aws_network_interface.test_node_nic.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 100
  }

  tags = {
    Name = "rke2-startup-script-test"
  }
}

resource "aws_security_group" "test_node_sg" {
  name        = "rke2-startup-script-test-sg"
  description = "SG providing settings for RKE2"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "All traffic from VPC for testing"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rke2-startup-script-test-sg"
  }
}