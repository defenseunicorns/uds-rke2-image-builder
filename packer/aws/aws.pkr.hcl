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

source "amazon-ebs" "ubuntu" {
  ami_name        = local.ami_name
  ami_description = "For UDS deployments on RKE2"
  instance_type   = "t2.micro"
  region          = "us-west-2"
  ssh_username    = "ubuntu"
  source_ami      = var.base_ami

  skip_create_ami = var.skip_create_ami
}

build {
  name    = local.ami_name
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    environment_vars = [
      "UBUNTU_PRO_TOKEN=${var.ubuntu_pro_token}"
    ]
    // STIG-ing must be run as root
    execute_command   = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script            = "../scripts/stig.sh"
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

}
