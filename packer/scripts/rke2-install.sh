#!/bin/bash

# If Network Manager is being used configure it to ignore calico/flannel network interfaces
if [[ $(systemctl list-units --full -all | grep -Poi "NetworkManager.service") ]]; then
  # Indent with tabs to prevent spaces in heredoc output
	cat <<- EOF > /etc/NetworkManager/conf.d/rke2-canal.conf
	[keyfile]
	unmanaged-devices=interface-name:cali*;interface-name:flannel*
	EOF
  systemctl reload NetworkManager
fi

# If present, disable firewalld which interferes with cluster networking
if [[ $(systemctl list-units --full -all | grep -Poi "firewalld.service") ]]; then
  systemctl disable firewalld.service
fi

# If present, disable additional network manager services that interfere with cluster networking
if [[ $(systemctl list-units --full -all | grep -Poi "nm-cloud-setup.service") ]]; then
  systemctl disable nm-cloud-setup.service
fi
if [[ $(systemctl list-units --full -all | grep -Poi "nm-cloud-setup.timer") ]]; then
  systemctl disable nm-cloud-setup.timer
fi

echo "Installing RKE2 $INSTALL_RKE2_VERSION..."

# Stage image artifacts
mkdir -p /var/lib/rancher/rke2/agent/images/ && cd /var/lib/rancher/rke2/agent/images/
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images-core.linux-amd64.tar.zst"
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images-canal.linux-amd64.tar.zst"

# Stage RKE2 install scripts/binary
mkdir -p /root/rke2-artifacts && cd /root/rke2-artifacts/
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images.linux-amd64.tar.zst"
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2.linux-amd64.tar.gz"
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/sha256sum-amd64.txt"
curl -sfL https://get.rke2.io --output install.sh

# Run install script
cd /root/rke2-artifacts/ && chmod +x install.sh
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts ./install.sh
