variable "vpc_name" {
  type        = string
  description = "VPC ID to deploy into"
  default     = "uds-ci-commercial-842d"
}

variable "subnet_name" {
  type        = string
  description = "Name of subnet to use for testing. Can use a wildcard as long as it only matches one subnet per az."
  default     = "uds-ci-commercial-842d-public*"
}

variable "region" {
  type        = string
  description = "Region to use for deployment"
  default     = "us-west-2"
}

variable "control_plane_node_count" {
  type        = number
  description = "How many control plane nodes to spin up. Total control plane nodes will be n+1 due to bootstrap node. For HA, there should be an odd number of control plane nodes."
  default     = 2
}

variable "agent_node_count" {
  type        = number
  description = "How many agent nodes to spin up"
  default     = 0
}

variable "allowed_in_cidrs" {
  type        = list(string)
  description = "Optional list of CIDRs that can connect to the cluster in addition to CIDR of VPC cluster is deployed to"
  default     = []
}

variable "cluster_sans" {
  type        = list(string)
  description = "Optional list of TLS SANs for RKE2 to include on cluster cert. Should include any public IPs and/or hostnames used to connect to the kubernetes API. cluster.foo.bar default used by CI tests"
  default     = []
}

variable "cluster_hostname" {
  type        = string
  description = "Hostname to use for connecting to cluster API. Gets merged with cluster_sans list var. cluster.foo.bar default used by CI tests"
  default     = "cluster.foo.bar"
}

variable "ami_id" {
  type        = string
  description = "AMI to use for deployment, must have RKE2 pre-installed"
}

variable "os_distro" {
  type        = string
  description = "OS distribution used to distinguish test infra based on which test created it"
}

variable "default_user" {
  type        = string
  description = "Default user of AMI"
}

variable "ssh_key_name" {
  type        = string
  description = "What to name generated SSH key pair in AWS"
}
