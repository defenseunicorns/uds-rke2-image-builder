#!/bin/bash
set -e

# If Network Manager is being used configure it to ignore calico/flannel network interfaces - https://docs.rke2.io/known_issues#networkmanager
if [[ $(systemctl list-units --full -all | grep -Poi "NetworkManager.service") ]]; then
  # Indent with tabs to prevent spaces in heredoc output
	cat <<- EOF > /etc/NetworkManager/conf.d/rke2-canal.conf
	[keyfile]
	unmanaged-devices=interface-name:cali*;interface-name:flannel*
	EOF
  systemctl reload NetworkManager
fi

# If present, disable services that interfere with cluster networking - https://docs.rke2.io/known_issues#firewalld-conflicts-with-default-networking
services_to_disable=("firewalld" "nm-cloud-setup" "nm-cloud-setup.timer")
for service in "${services_to_disable[@]}"; do
  if systemctl list-units --full -all | grep -Poi "$service.service" &>/dev/null; then
    systemctl disable "$service.service"
  fi
done

# Get image artifacts - https://docs.rke2.io/install/airgap#tarball-method
mkdir -p /var/lib/rancher/rke2/agent/images/ && cd /var/lib/rancher/rke2/agent/images/
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images-core.linux-amd64.tar.zst"
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images-canal.linux-amd64.tar.zst"

# Run RKE2 install script - https://docs.rke2.io/install/airgap#rke2-installsh-script-install
mkdir -p /root/rke2-artifacts && cd /root/rke2-artifacts/
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images.linux-amd64.tar.zst"
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2.linux-amd64.tar.gz"
curl -LO "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/sha256sum-amd64.txt"
curl -sfL https://get.rke2.io --output install.sh
cd /root/rke2-artifacts/ && chmod +x install.sh
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts ./install.sh
