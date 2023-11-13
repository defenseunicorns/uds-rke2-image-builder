#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Install dependencies and cli tools needed by other packer scripts
if [[ $DISTRO == "rhel" ]]; then
  yum update -y && yum upgrade -y
  yum install ansible unzip -y
  #  Install rke2 selinux policy
  curl -LO "https://github.com/rancher/rke2-selinux/releases/download/v0.14.stable.1/rke2-selinux-0.14-1.el8.noarch.rpm"
  yum install rke2-selinux-0.14-1.el8.noarch.rpm -y
  # Install lvm2 for storage (e.x. rook/ceph)
  yum install lvm2 -y
elif [[ $DISTRO == "ubuntu" ]]; then
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
  apt-add-repository ppa:ansible/ansible -y
  apt-get update -y && apt-get upgrade -y
  apt-get install ansible unzip jq -y
  # Install lvm2 for storage (e.x. rook/ceph)
  apt-get install lvm2 -y
fi

# Ensure that ansible collections needed are installed 
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix    
