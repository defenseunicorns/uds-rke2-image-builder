#!/bin/bash

# Detect distro. This works fine with only rhel and ubuntu in the list, but will not work as is if you need to distinguish ubuntu/debian or rhel/fedora
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

echo "Executing STIG automation..."

# Pull Ansible STIGs from https://public.cyber.mil/stigs/supplemental-automation-content/
mkdir -p /tmp/ansible && chmod 700 /tmp/ansible && cd /tmp/ansible
# TODO determine stig download based on os-release version
if [[ $DISTRO == "rhel" ]]; then
  curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_8_V1R11_STIG_Ansible.zip
elif [[ $DISTRO == "ubuntu" ]]; then
  curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_CAN_Ubuntu_20-04_LTS_V1R9_STIG_Ansible.zip
fi
unzip ansible.zip
unzip *-ansible.zip
chmod +x enforce.sh && ./enforce.sh

# FIPS - Conditionally performed based on subscription being attached
if [[ $DISTRO == "ubuntu" ]]; then
  if [[ $UBUNTU_PRO_TOKEN ]]; then
    pro attach $UBUNTU_PRO_TOKEN
  fi
  if [[ $(pro status --format json | jq '.attached') == "true" ]]; then
    apt-get install ubuntu-advantage-tools -y
    pro enable fips-updates --assume-yes
    reboot # Reboot to enable FIPS before proceeding
  fi
fi
