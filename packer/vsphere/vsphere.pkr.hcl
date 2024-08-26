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
  vm_name = "${var.packer_vm_name}_${var.k8s_distro}"
  content_library_item_description = var.content_library_item_description != null ? var.content_library_item_description : local.vm_name
  shutdown_command = var.packer_vm_shutdown_command == "" ? "sudo su -c \"shutdown -P now\"" : var.packer_vm_shutdown_command 
  http_content = {
    "/uds.ks" = templatefile("${abspath(path.root)}/http_ks/ks.pkrtpl", { 
      root_password = bcrypt(var.root_password) 
      rhsm_username = var.rhsm_username
      rhsm_password = var.rhsm_password
      persistent_admin_username = var.persistent_admin_username
      persistent_admin_password = bcrypt(var.persistent_admin_password)
    })
  }
}

source "vsphere-iso" "rke2-rhel-base" {
  # vSphere connection
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_username
  password            = var.vsphere_password
  insecure_connection = var.allow_unverified_ssl
  datacenter          = var.datacenter_name

  # Temporary VM location configuration
  vm_name = local.vm_name
  folder  = var.packer_folder_name
  cluster = var.packer_cluster_name
  datastore = var.datastore_name

  # Temporary VM network configuration
  ip_wait_address  = var.vm_ip_cidr
  dynamic "network_adapters" {
    iterator = na
    for_each = var.network_adapters
    content {
      network      = na.value["network"]
      network_card = na.value["network_card"]
    }
  }

  # Temporary VM storage configuration
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

  # Temporary VM guest OS
  iso_paths = ["${var.content_library_name}/${var.iso_filepath}"]
  guest_os_type = var.os_type
  
  # Temporary VM boot configuration
  boot_command = var.boot_command
  http_content = local.http_content
  http_ip = var.http_ip != null ? var.http_ip : "" 
  
  # Temporary VM shutdown configuration
  shutdown_timeout = var.packer_vm_shutdown_timeout
  shutdown_command = local.shutdown_command
  remove_network_adapter = true

  # Temporary VM resources
  CPUs = var.CPUs
  RAM  = var.RAM

  # OVF Template configuration
  remove_cdrom = var.remove_cdrom

  # Content Library
  content_library_destination {
    cluster = var.packer_cluster_name
    library = var.content_library_name
    name = var.content_library_item_name != null ? var.content_library_item_name : "${local.vm_name}-${formatdate("DD-MM-YYYY_hh-mm-ss",timestamp())}"
    description = local.content_library_item_description
    ovf = true
    skip_import = var.skip_import
    destroy = true
  }

  # Communicator
  communicator = "ssh"
  ssh_username = "root"
  ssh_password = var.root_password 
}

build {

  sources = ["source.vsphere-iso.rke2-rhel-base"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "../scripts/install-deps.sh"
    timeout         = "20m"
  }

  provisioner "shell" {
    environment_vars = [
      "UBUNTU_PRO_TOKEN=${var.ubuntu_pro_token}"
    ]
    // STIG-ing must be run as root
    execute_command   = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script            = "../scripts/os-stig.sh"
    expect_disconnect = true
    timeout           = "20m"
  }

  provisioner "shell" {
    environment_vars = [
      "INSTALL_RKE2_VERSION=${var.rke2_version}"
    ]
    // RKE2 artifact unpacking/install must be run as root
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "../scripts/rke2-install.sh"
    timeout         = "15m"
  }

  provisioner "shell" {
    // RKE2 artifact unpacking/install must be run as root
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "../scripts/os-prep.sh"
    timeout         = "15m"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "../scripts/cleanup-deps.sh"
    timeout         = "15m"
  }

  provisioner "file" {
    source      = "../scripts/rke2-startup.sh"
    destination = "/tmp/rke2-startup.sh"
  }

  provisioner "file" {
    source      = "../files"
    destination = "/tmp"
  }

  provisioner "shell" {
    environment_vars = [
      "RKE2_STARTUP_DIR=/opt"
    ]
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "../scripts/rke2-config.sh"
    timeout         = "15m"
  }

  post-processors {
    post-processor "vsphere-template" {
      host                = var.vsphere_server
      insecure            = var.allow_unverified_ssl
      username            = var.vsphere_username
      password            = var.vsphere_password
      datacenter          = var.datacenter_name
      folder              = var.packer_folder_name
    }
  }
}
