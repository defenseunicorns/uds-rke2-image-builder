#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Pull Ansible STIGs from https://public.cyber.mil/stigs/supplemental-automation-content/
mkdir -p /tmp/ansible && chmod 700 /tmp/ansible && cd /tmp/ansible
if [[ $DISTRO == "rhel" ]]; then
  # Determine which stigs to apply based on RHEL version
  VERSION=$( cat /etc/os-release | grep -Poi '^version="[0-9]+\.[0-9]+' | cut -d\" -f2 | cut -d. -f1 )
  if [[ ${VERSION} -eq 9 ]] ; then
    curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_9_V1R2_STIG_Ansible.zip
  elif [[ ${VERSION} -eq 8 ]]; then
    curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_8_V1R13_STIG_Ansible.zip
  else
    echo "Unrecognized RHEL version, exiting"
    exit 1
  fi
elif [[ $DISTRO == "ubuntu" ]]; then
  curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_CAN_Ubuntu_20-04_LTS_V1R11_STIG_Ansible.zip
fi
unzip ansible.zip
unzip *-ansible.zip

# Remove do_reboot handler from tasks file - VMs used to create templates from packer will be booted later for SELINUX changes to take effect
TASKS_FILE=$( find roles/*/tasks -name main.yml -type f )
sed -i '/notify: do_reboot/d' $TASKS_FILE

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
