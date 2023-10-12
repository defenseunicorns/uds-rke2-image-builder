#!/bin/bash
# Setup RKE2 configuration files

config_dir=/etc/rancher/rke2
config_file=$config_dir/config.yaml
stig_conf_dir=/tmp/stig-configs
mkdir -p $config_dir

# Stage startup helper script
cp /tmp/rke2-startup.sh /root/rke2-startup.sh 
chmod +x /root/rke2-startup.sh 
chown root:root /root/rke2-startup.sh

# Stage STIG config files
mv -f $stig_conf_dir/rke2-config.yaml $config_file
chown -R root:root $config_file
mv -f $stig_conf_dir/audit-policy.yaml $config_dir/audit-policy.yaml
chown -R root:root $config_dir/audit-policy.yaml
mv -f $stig_conf_dir/default-pss.yaml $config_dir/default-pss.yaml
chown -R root:root $config_dir/default-pss.yaml
