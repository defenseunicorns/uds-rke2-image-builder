packer {
  required_version = ">= 1.9.0"
  required_plugins {
    vsphere = {
      source  = "github.com/hashicorp/vsphere"
      version = ">= 1.3.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.0"
    }
  }
}

locals {
  vm_name = "${var.uds_packer_vm_name}_${var.k8s_distro}_${var.k8s_node_role}"
  uds_content_library_item_description = var.uds_content_library_item_description != null ? var.uds_content_library_item_description : local.vm_name
}

source "vsphere-iso" "rke2-rhel-base" {
  # vSphere connection
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_user
  password            = var.vsphere_password
  insecure_connection = var.allow_unverified_ssl
  datacenter          = var.uds_datacenter_name

  # Location configuration
  vm_name = local.vm_name
  folder  = var.uds_packer_folder_name
  cluster = var.uds_packer_cluster_name
  datastore = var.uds_datastore_name

  # VM Network configuration
  ip_wait_address  = var.vm_ip_cidr
  dynamic "network_adapters" {
    iterator = na
    for_each = var.network_adapters
    content {
      network      = na.value["network"]
      network_card = na.value["network_card"]
    }
  }

  # VM Storage configuration
  disk_controller_type = var.vm_disk_controller_type

  dynamic "storage" {
    for_each = var.vm_disk_configurations
    content {
      disk_size      = storage.value["disk_size"]
      disk_controller_index = storage.value["disk_controller_index"]
      disk_thin_provisioned = storage.value["disk_thin_provisioned"]
      disk_eagerly_scrub = storage.value["disk_eagerly_scrub"]
    }
  }

  # ISO location
  iso_paths = ["${var.uds_content_library_name}/${var.uds_iso_filepath}"]

  # Guest OS
  guest_os_type = var.uds_os_type

  # Resources
  CPUs = var.CPUs
  RAM  = var.RAM

  # OVF Template configuration
  remove_cdrom = var.remove_cdrom

  # Content Library
  content_library_destination {
    cluster = var.uds_packer_cluster_name
    library = var.uds_content_library_name
    name = var.uds_content_library_item_name != null ? var.uds_content_library_item_name : "${local.vm_name}-${formatedate("DD-MM-YYYY_hh-mm-ss",timestamp())}"
    description = local.uds_content_library_item_description
    ovf = true
    destroy = true
  }

  # Boot configuration
  boot_command = var.boot_command
  http_directory = var.http_directory
  http_ip = var.http_ip != null ? var.http_ip : "" 

  # Communicator
  communicator = "ssh"
  ssh_username = var.packer_ssh_username
  ssh_password = var.packer_ssh_password
  
  # Shutdown configuration
  shutdown_timeout = var.uds_packer_vm_shutdown_timeout
  #destroy          = true
  remove_network_adapter = true
}

build {
  sources = ["source.vsphere-iso.rke2-rhel-base"]
}
