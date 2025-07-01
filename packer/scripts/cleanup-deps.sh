#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Cleanup dependencies and utils that shouldn't be in final image
if [[ $DISTRO == "rhel" ]]; then
  VERSION=$( cat /etc/os-release | grep -Poi '^version="[0-9]+\.[0-9]+' | cut -d\" -f2 | cut -d. -f1 )

  yum remove unzip -y

  if [[ ${VERSION} -eq 9 ]]; then
    yum remove ansible-core -y
  else
    python3.9 -m pip uninstall ansible -y
    yum remove python39 python39-pip -y
  fi

  # Install nfs-utils here since the STIG profile seems to uninstall it
  yum install nfs-utils -y
elif [[ $DISTRO == "ubuntu" ]]; then
  apt-get remove ansible-core unzip jq -y
  apt-get autoremove -y
fi

cd && rm -rf /tmp/*
