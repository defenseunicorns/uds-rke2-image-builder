#!/bin/bash
# Install dependencies and cli tools needed by other packer scripts

# Detect distro. This works fine with only rhel and ubuntu in the list, but will not work as is if you need to distinguish ubuntu/debian or rhel/fedora
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

if [[ $DISTRO == "rhel" ]]; then
    yum install ansible unzip iptables nftables -y
elif [[ $DISTRO == "ubuntu" ]]; then
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
    apt-add-repository ppa:ansible/ansible -y
    apt-get update -y && apt-get upgrade -y
    apt-get install ansible unzip iptables-persistent -y
else
    echo "$DISTRO not an expected distribution."
fi

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl