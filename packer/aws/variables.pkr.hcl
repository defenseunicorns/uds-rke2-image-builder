variable "ami_name" {
  type        = string
  description = "Name to use for the published AMI"
  default     = "uds-rke2"
}

variable "timestamp" {
  type        = bool
  description = "Append a timestamp to the end of the published AMI name"
  default     = true
}

variable "base_ami" {
  type        = string
  description = "AMI to build on top of, scripts validated on Ubuntu 20.04"
  // ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230725
  default = "ami-03fc394d884ee7d48"
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
