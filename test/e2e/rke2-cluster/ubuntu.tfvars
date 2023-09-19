default_user = "ubuntu"
ssh_key_name = "packer-rke2-ubuntu-key"
os_distro    = "ubuntu"
# Need to allow in from internet for github runner to connect to node
allowed_in_cidrs = ["0.0.0.0/0"]