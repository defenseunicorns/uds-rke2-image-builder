provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
  }
}

data "aws_vpc" "vpc" {
  filter {
    name = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "test_subnet" {
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = "${var.region}a"

  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

resource "random_password" "rke2_join_token" {
  length  = 40
  special = false
}

# Private key is generated as part of this example only for demo/testing purposes
resource "tls_private_key" "example_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "example_key_pair" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.example_private_key.public_key_openssh
}

resource "aws_instance" "test_bootstrap_node" {
  ami           = var.ami_id
  instance_type = var.control_plane_instance_type
  key_name      = aws_key_pair.example_key_pair.key_name
  user_data     = templatefile("${path.module}/scripts/user_data.sh", { BOOTSTRAP_IP = "", AGENT_NODE = false, RKE2_JOIN_TOKEN = random_password.rke2_join_token.result })
  subnet_id     = data.aws_subnet.test_subnet.id
  user_data_replace_on_change = true

  vpc_security_group_ids = [aws_security_group.test_node_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 100
  }

  tags = {
    Name = "${var.os_distro}-rke2-test-bootstrap"
  }
}

resource "aws_instance" "test_control_plane_node" {
  count = var.control_plane_node_count

  ami           = var.ami_id
  instance_type = var.control_plane_instance_type
  key_name      = aws_key_pair.example_key_pair.key_name
  user_data     = templatefile("${path.module}/scripts/user_data.sh", { BOOTSTRAP_IP = aws_instance.test_bootstrap_node.private_ip, AGENT_NODE = false, RKE2_JOIN_TOKEN = random_password.rke2_join_token.result })
  subnet_id     = data.aws_subnet.test_subnet.id
  user_data_replace_on_change = true

  vpc_security_group_ids = [aws_security_group.test_node_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 100
  }

  tags = {
    Name = "${var.os_distro}-rke2-test-control"
  }
}

resource "aws_instance" "test_agent_node" {
  count = var.agent_node_count

  ami           = var.ami_id
  instance_type = var.agent_instance_type
  key_name      = aws_key_pair.example_key_pair.key_name
  user_data     = templatefile("${path.module}/scripts/user_data.sh", { BOOTSTRAP_IP = aws_instance.test_bootstrap_node.private_ip, AGENT_NODE = true, RKE2_JOIN_TOKEN = random_password.rke2_join_token.result })
  subnet_id     = data.aws_subnet.test_subnet.id
  user_data_replace_on_change = true

  vpc_security_group_ids = [aws_security_group.test_node_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 100
  }

  tags = {
    Name = "${var.os_distro}-rke2-test-agent"
  }
}

resource "aws_security_group" "test_node_sg" {
  name        = "${var.os_distro}-rke2-test-sg"
  description = "SG providing settings for RKE2"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "All traffic from VPC for testing"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = concat([data.aws_vpc.vpc.cidr_block], var.allowed_in_cidrs)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.os_distro}-rke2-test-sg"
  }
}
