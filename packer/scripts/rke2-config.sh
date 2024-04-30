#!/bin/bash
set -e

# Setup RKE2 configuration files
config_dir=/etc/rancher/rke2
config_file=$config_dir/config.yaml
file_dir=/tmp/files
mkdir -p $config_dir

# Stage startup helper script
mv -f /tmp/rke2-startup.sh /root/rke2-startup.sh
chmod +x /root/rke2-startup.sh 
chown root:root /root/rke2-startup.sh

# Stage STIG config files
mv -f $file_dir/rke2-config.yaml $config_file
chown -R root:root $config_file
mv -f $file_dir/audit-policy.yaml $config_dir/audit-policy.yaml
chown -R root:root $config_dir/audit-policy.yaml
mv -f $file_dir/default-pss.yaml $config_dir/default-pss.yaml
chown -R root:root $config_dir/default-pss.yaml

# Configure settings needed by CIS profile and add etcd user
sudo cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
sudo systemctl restart systemd-sysctl
sudo useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U

# Copy temporary containerd workaround configuration
sudo mkdir -p /var/lib/rancher/rke2/agent/etc/containerd
sudo mv -f $file_dir/config.toml.tmpl /var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl
