#!/bin/bash

echo "Executing STIG automation..."

# Install ansible and unzip utils
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
apt-add-repository ppa:ansible/ansible -y
apt-get update -y && apt-get upgrade -y
apt-get install ansible unzip -y

# Pull Ansible STIGs from https://public.cyber.mil/stigs/supplemental-automation-content/
mkdir -p /tmp/ansible && chmod 700 /tmp/ansible && cd /tmp/ansible
curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_CAN_Ubuntu_20-04_LTS_V1R9_STIG_Ansible.zip
unzip ansible.zip
unzip ubuntu2004STIG-ansible.zip
chmod +x enforce.sh && ./enforce.sh

# Cleanup temp files and utils
apt-get remove ansible unzip -y
apt-get autoremove -y
cd && rm -rf /tmp/*

# FIPS - Conditionally performed based of subscription being provided
if [[ $UBUNTU_PRO_TOKEN ]]; then
  pro attach $UBUNTU_PRO_TOKEN
  apt-get install ubuntu-advantage-tools -y
  pro enable fips-updates --assume-yes # TBD should this just be the `fips` "certified" install?
  reboot # Reboot to enable FIPS before proceeding
fi
