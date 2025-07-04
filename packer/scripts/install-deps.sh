#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Install dependencies and cli tools needed by other packer scripts
if [[ $DISTRO == "rhel" ]]; then
  # Determine which stigs to apply based on RHEL version
  VERSION=$( cat /etc/os-release | grep -Poi '^version="[0-9]+\.[0-9]+' | cut -d\" -f2 | cut -d. -f1 )

  yum update -y && yum upgrade -y
  yum install unzip nfs-utils nfs4-acl-tools lvm2 iscsi-initiator-utils -y

  # Install Ansible
  if [[ ${VERSION} -eq 9 ]]; then
    # On RHEL 9 we can install with yum
    yum install ansible-core -y
  else
    # In RHEL 8, we need to use pip
    yum install python39 python39-pip -y
    python3.9 -m pip install --upgrade ansible
  fi
  # Temporarily add /usr/local/bin to PATH to ensure ansible is available
  export PATH=$PATH:/usr/local/bin

  #  Install rke2 selinux policy
  if [[ ${VERSION} -eq 9 ]] ; then
    curl -LO "https://github.com/rancher/rke2-selinux/releases/download/v0.20.stable.1/rke2-selinux-0.20-1.el9.noarch.rpm"
    yum install rke2-selinux-0.20-1.el9.noarch.rpm -y
  elif [[ ${VERSION} -eq 8 ]]; then
    curl -LO "https://github.com/rancher/rke2-selinux/releases/download/v0.20.stable.1/rke2-selinux-0.20-1.el8.noarch.rpm"
    yum install rke2-selinux-0.20-1.el8.noarch.rpm -y
  else
    echo "Unrecognized RHEL version, exiting"
    exit 1
  fi

elif [[ $DISTRO == "ubuntu" ]]; then
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
  apt-get update -y && apt-get upgrade -y
  apt-get install software-properties-common -y
  add-apt-repository -y --update ppa:ansible/ansible
  apt-get install ansible-core unzip jq -y
  # Install lvm2 for storage (e.x. rook/ceph)
  apt-get install lvm2 -y
  # Keep CA Certs up to date
  update-ca-certificates
fi

# Ensure that ansible collections needed are installed 
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix    
