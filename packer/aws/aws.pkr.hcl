packer {
  required_version = ">= 1.9.2"

  required_plugins {
    amazon = {
      version = ">= 1.2.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  ami_name = var.timestamp ? lower("${var.ami_name}-${replace(var.rke2_version, "+", "-")}-${formatdate("YYYYMMDDhhmm", timestamp())}") : lower("${var.ami_name}-${replace(var.rke2_version, "+", "-")}")
}

data "amazon-ami" "base-ami" {
  filters = {
    name = var.base_ami_name
  }
  owners      = var.base_ami_owners
  most_recent = true
  region      = var.region
}

source "amazon-ebs" "base" {
  ami_name        = local.ami_name
  ami_regions     = var.ami_regions
  ami_description = "For UDS deployments on RKE2"
  instance_type   = "t2.micro"
  region          = var.region
  ssh_username    = var.ssh_username
  source_ami      = data.amazon-ami.base-ami.id
  ami_groups      = var.ami_groups
  skip_create_ami = var.skip_create_ami
}

build {
  name    = local.ami_name
  sources = ["source.amazon-ebs.base"]

  // Ubuntu Pro subscription attachment happens during cloud-init when using a Pro AMI
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    inline          = ["cloud-init status --wait"]
    timeout         = "20m"
  }

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
    expect_disconnect = true // Expect a restart due to FIPS reboot
    timeout           = "20m"
  }

  provisioner "shell" {
    environment_vars = [
      "INSTALL_RKE2_VERSION=${var.rke2_version}"
    ]
    // RKE2 artifact unpacking/install must be run as root
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "../scripts/rke2-install.sh"
    expect_disconnect = true // Sometimes the connection is lost during the install
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
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "../scripts/rke2-config.sh"
    timeout         = "15m"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }

}
