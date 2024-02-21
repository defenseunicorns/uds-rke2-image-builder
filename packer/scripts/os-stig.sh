#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Pull Ansible STIGs from https://public.cyber.mil/stigs/supplemental-automation-content/
mkdir -p /tmp/ansible && chmod 700 /tmp/ansible && cd /tmp/ansible
if [[ $DISTRO == "rhel" ]]; then
  curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_8_V1R12_STIG_Ansible.zip
elif [[ $DISTRO == "ubuntu" ]]; then
  curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_CAN_Ubuntu_20-04_LTS_V1R11_STIG_Ansible.zip
fi
unzip ansible.zip
unzip *-ansible.zip
chmod +x enforce.sh && ./enforce.sh

# FIPS enabling - conditional for Ubuntu dependent on subscription
if [[ $DISTRO == "ubuntu" ]]; then
  if [[ $UBUNTU_PRO_TOKEN ]]; then
    pro attach $UBUNTU_PRO_TOKEN
  fi
  if [[ $(pro status --format json | jq '.attached') == "true" ]]; then
    apt-get install ubuntu-advantage-tools -y
    pro enable fips-updates --assume-yes
    reboot
  fi
fi
