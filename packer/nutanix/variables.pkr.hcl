variable "output_image_name" {
  type        = string
  description = "Name to use for the published image"
}

variable "timestamp" {
  type        = bool
  description = "Append a timestamp to the end of the published image name"
  default     = true
}

variable "base_image_name" {
  type        = string
  description = "Name of disk image in cluster to use as base image, tested with Ubuntu 20/04 and RHEL 8"
}

variable "rke2_version" {
  type        = string
  description = "RKE2 version to install on the Image"
  default     = "v1.29.1+rke2r1"
}

variable "ubuntu_pro_token" {
  type        = string
  description = "Token for a valid Ubuntu Pro subscription to use for FIPS packages"
  default     = ""
  sensitive   = true
}

variable "image_delete" {
  type        = bool
  description = "Build, but delete the final image rather than saving on Prism Central"
  default     = false
}

variable "image_export" {
  type        = bool
  description = "Export raw image in the current folder"
  default     = false
}

variable "nutanix_username" {
  type        = string
  description = "Username for Prism Central"
}

variable "nutanix_password" {
  type        = string
  description = "Password for Prism Central"
  sensitive   = true
}

variable "nutanix_endpoint" {
  type        = string
  description = "Endpoint (URL/IP) for Prism Central"
}

variable "nutanix_port" {
  type        = number
  description = "Port for Prism Central"
  default     = 9440
}

variable "nutanix_insecure" {
  type        = bool
  description = "Whether connection to Prism Central should be insecure"
  default     = false
}

variable "nutanix_cluster" {
  type        = string
  description = "Name of cluster to use for Packer build VM"
}

variable "nutanix_subnet" {
  type        = string
  description = "Name of subnet in cluster to use for Packer build VM"
}
