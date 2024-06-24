variable "vsphere_username" {
  sensitive   = true
  type        = string
  description = "User used to authenticate with vSphere API"
}

variable "vsphere_password" {
  sensitive   = true
  type        = string
  description = "Password used to authenticate with vSphere API"
}

variable "vsphere_server" {
  type        = string
  default     = "192.168.10.11"
  description = "FQDN or IP of the vSphere API"
}

variable "allow_unverified_ssl" {
  type        = bool
  default     = true
  description = "Set to false to force SSL verification of vSphere server certificate"
}

variable "CPUs" {
  type = number
  default = 2
  description = "Number of CPUs to make available to Packer build VM"
}

variable "RAM" {
  type = number
  default = 8000
  description = "RAM in MB to make available to Packer build VM"
}

variable "uds_datacenter_name" {
  type        = string
  default     = "UDS_DC"
  description = "Name of the vSphere Datacenter to use for the Packer build"
}

variable "uds_datastore_name" {
  type        = string
  default     = "192.168.10.3-ds"
  description = "Name of the vSphere Datacenter to use for the Packer build"
}

variable "uds_packer_folder_name" {
  type        = string
  default     = "UDS_Node_Builds"
  description = "Name of the folder in which to place the Packer VM"
}

variable "uds_packer_vm_shutdown_timeout" {
  type = string
  default = "7m"
  description = "Amount of time to wait for the Packer VM to shut down after the build is complete."
}

variable "uds_packer_vm_shutdown_command" {
  type = string
  default = ""
  description = "Shut down command after the build is complete."
}

variable "http_directory" {
  type = string
  default = "http_ks"
  description = "Name of the local directory containing the kickstart file to be used for booting the UDS nodes"
}

variable "boot_command" {
  type = list(string)
  default = ["<up>","<tab>","<spacebar>","inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/uds.ks", "<enter>"]
  description = "Boot command to execute on the build VM"
}

variable "http_ip" {
  type = string
  default = null
  description = "IP address to serve the kickstart file at"
}

variable "uds_packer_cluster_name" {
  type        = string
  default     = "UDS_CC"
  description = "Name of the vSphere compute cluster to use for the Packer VM"
}

variable "uds_datastore_cluster_name" {
  type        = string
  default     = "UDS_DSC"
  description = "Name of the vsphere datastore to create."
}

variable "uds_content_library_name" {
  type        = string
  default     = "UDS_CL-192.168.10.3"
  description = "Content library storing iso used for UDS node build"
}

variable "uds_iso_filepath" {
  type        = string
  default     = "rhel-9.4-x86_64-dvd/rhel-9.4-x86_64-dvd.iso"
  description = "File path for iso within uds_iso_content_library used for UDS node build"
}

variable "uds_os_type" {
  type        = string
  default     = "rhel9_64Guest"
  description = "guestid for VM. See https://docs.vmware.com/en/VMware-HCX/4.9/hcx-user-guide/GUID-D4FFCBD6-9FEC-44E5-9E26-1BD0A2A81389.html for a (slightly outdated) list"
}

variable "iso_cdrom_type" {
  type        = string
  default     = "sata"
  description = "VM CDROM type"
}

variable "remove_cdrom" {
  type        = bool
  default     = true
  description = "Remove CDROM from created VM Template"
}

variable "vm_ip_cidr" {
  type        = string
  default     = "192.168.0.0/24"
  description = "IP CIDR from which an IP will be assigned for the VM"
}

variable "network_adapters" {
  type = list(object(
    {
      network      = string
      network_card = string
    }
  ))
  default = [{
    network      = "VM Network"
    network_card = "vmxnet3"
  }]
  description = <<EOT
    network_adapters = [{
      network : Network on which to start the build VM
      network_card : Network card type to attach to the build VM
    }]
  EOT
}

variable "vm_disk_configurations" {
  type = list(object(
    {
      disk_size      = number
      disk_controller_index = number
      disk_thin_provisioned = bool
      disk_eagerly_scrub = bool
    }
  ))
  default = [{
    disk_size      = 20000
    disk_controller_index = 0
    disk_thin_provisioned = false
    disk_eagerly_scrub = false
  }]
  description = <<EOT
    vm_disk_configurations = [{
      disk_size : Size of the disk in MiB
      disk_controller_index : The assigned disk controller
      disk_thin_provisioned : Enable VMDK thin provisioning
      disk_eagerly_scrub : Enable VMDK eager scrubbing
    }]
  EOT
}

variable "k8s_node_role" {
  type = string
  default = "control_plane"
  validation {
    condition = var.k8s_node_role == "control_plane" || var.k8s_node_role == "worker"
    error_message = "Variable k8_node_role must be one of 'control_plane' or 'worker'."
  }
  description = "Defines if the node is being provisioned as a control plane or worker node."
}

variable "k8s_distro" {
  type = string
  default = "rke2"
  description = "The Kubernetes distribution being installed"
}

variable "uds_packer_vm_name" {
  type = string
  default = "uds_node"
  description = "Name for the VM created in vSphere by Packer"
}

variable "uds_content_library_item_description" {
  type = string
  default = null
  description = "Description for the item published to the vSphere content library"
}

variable "uds_content_library_item_name" {
  type = string
  default = null
  description = "Name for the item published to the vSphere content library"
}

variable "root_password" {
  type = string
  description = "Password to set for the root user on boot"
  sensitive   = true
}

variable "packer_ssh_username" {
  type        = string
  description = "The username to login to the guest operating system."
  sensitive   = true
}

variable "packer_ssh_password" {
  type        = string
  description = "The password to login to the guest operating system."
  sensitive   = true
}

variable "rhsm_username" {
  type        = string
  description = "The username to register with Redhat Subscription Manager"
  sensitive   = true
}

variable "rhsm_password" {
  type        = string
  description = "The password to register with Redhat Subscription Manager"
  sensitive   = true
}

variable "vm_disk_controller_type" {
  type = list(string)
  default = ["pvscsi"]
  description = "Determines the type(s), in sequence, of disk controllers used"
}

variable "rke2_version" {
  type        = string
  description = "RKE2 version to install on the Image"
  default     = "v1.29.3+rke2r1"
}

variable "ubuntu_pro_token" {
  type        = string
  description = "Token for a valid Ubuntu Pro subscription to use for FIPS packages"
  default     = ""
  sensitive   = true
}
