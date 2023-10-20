#!/bin/bash
set -e

# Setup RKE2 configuration files
config_dir=/etc/rancher/rke2
config_file=$config_dir/config.yaml
stig_conf_dir=/tmp/stig-configs
mkdir -p $config_dir

# Stage startup helper script
mv -f /tmp/rke2-startup.sh /root/rke2-startup.sh
chmod +x /root/rke2-startup.sh 
chown root:root /root/rke2-startup.sh

# Stage STIG config files
mv -f $stig_conf_dir/rke2-config.yaml $config_file
chown -R root:root $config_file
mv -f $stig_conf_dir/audit-policy.yaml $config_dir/audit-policy.yaml
chown -R root:root $config_dir/audit-policy.yaml
mv -f $stig_conf_dir/default-pss.yaml $config_dir/default-pss.yaml
chown -R root:root $config_dir/default-pss.yaml

# Configure settings needed by CIS profile and add etcd user
sudo cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
sudo systemctl restart systemd-sysctl
sudo useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
