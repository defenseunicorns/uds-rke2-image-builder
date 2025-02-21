#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Cleanup dependencies and utils that shouldn't be in final image
if [[ $DISTRO == "rhel" ]]; then
  yum remove unzip -y
  python3.9 -m pip uninstall ansible
  yum remove python3.9 python3.9-pip -y

  # Install nfs-utils here since the STIG profile seems to uninstall it
  yum install nfs-utils -y
elif [[ $DISTRO == "ubuntu" ]]; then
  apt-get remove ansible unzip jq -y
  apt-get autoremove -y
fi

cd && rm -rf /tmp/*
