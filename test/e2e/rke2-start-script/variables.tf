variable "vpc_id" {
  type        = string
  description = "VPC ID to deploy into"
  default     = "vpc-0007fc0c033f08824"
}

variable "ami_id" {
  type        = string
  description = "AMI to use for deployment, must have RKE2 pre-installed"
}

variable "region" {
  type        = string
  description = "Region to use for deployment"
  default     = "us-west-2"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of the SSH key to attach to the EC2"
  default     = null
}

variable "bootstrap_ip" {
  type        = string
  description = "IP address of RKE2 bootstrap node"
  default     = ""
}

variable "agent_node" {
  type        = bool
  description = "Should RKE2 start as agent"
  default     = false
}

variable "default_user" {
  type        = string
  description = "Default user of AMI"
}
