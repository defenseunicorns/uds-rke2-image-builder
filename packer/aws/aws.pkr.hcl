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
  ami_name = var.timestamp ? lower("${var.ami_name}-${formatdate("YYYYMMDDhhmm", timestamp())}") : lower(var.ami_name)
}

data "amazon-ami" "base-ami" {
  filters = {
    name = var.base_ami_name
  }
  owners      = var.base_ami_owners
  most_recent = true
}

source "amazon-ebs" "base" {
  ami_name        = local.ami_name
  ami_description = "For UDS deployments on RKE2"
  instance_type   = "t2.micro"
  region          = var.region
  ssh_username    = var.ssh_username
  source_ami      = data.amazon-ami.base-ami.id

  skip_create_ami = var.skip_create_ami
}

build {
  name    = local.ami_name
  sources = ["source.amazon-ebs.base"]

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
    expect_disconnect = length(var.ubuntu_pro_token) > 0
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
    script          = "../scripts/aws-cli-install.sh"
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
    source      = "../stig-configs"
    destination = "/tmp"
  }

  provisioner "shell" {
    environment_vars = [
      "default_user=${var.ssh_username}"
    ]
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    // Move files out of /tmp so they persist in created image
    script          = "../scripts/move-files.sh"
    timeout         = "15m"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }

}
