#!/bin/bash
# Cleanup cloud-init and machine-id, this is generally only needed for non-AWS environments

# Detect distro. This works fine with only rhel and ubuntu in the list, but will not work as is if you need to distinguish ubuntu/debian or rhel/fedora
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

cloud-init clean

if [[ $DISTRO == "rhel" ]]; then
  rm -rf /etc/machine-id
elif [[ $DISTRO == "ubuntu" ]]; then
  cloud-init clean --machine-id
else
  echo "$DISTRO not an expected distribution."
fi
