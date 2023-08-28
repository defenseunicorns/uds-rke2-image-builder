variable "ami_name" {
  type        = string
  description = "Name to use for the published AMI"
}

variable "timestamp" {
  type        = bool
  description = "Append a timestamp to the end of the published AMI name"
  default     = true
}

variable "base_ami_name" {
  type        = string
  description = "AMI to build on top of, builds validated against Ubuntu 20.04 and RHEL8"
}

variable "rke2_version" {
  type        = string
  description = "RKE2 version to install on the AMI"
  default     = "v1.26.7+rke2r1"
}

variable "ubuntu_pro_token" {
  type        = string
  description = "Token for a valid Ubuntu Pro subscription to use for FIPS packages"
  default     = ""
  sensitive   = true
}

variable "skip_create_ami" {
  type        = bool
  description = "Build, but skip creation of an AMI"
  default     = false
}

variable "ssh_username" {
  type        = string
  description = "Username used to connect to instance over SSH"
}

variable "base_ami_owners" {
  type        = list(string)
  description = "List of owners to filter looking up the base ami"
  default     = ["amazon"]
}