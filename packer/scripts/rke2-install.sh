#!/bin/bash
set -e

# Get image artifacts - https://docs.rke2.io/install/airgap#tarball-method
mkdir -p /var/lib/rancher/rke2/agent/images/ && cd /var/lib/rancher/rke2/agent/images/
wget --continue "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images-core.linux-amd64.tar.zst"
wget --continue "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images-canal.linux-amd64.tar.zst"

# Run RKE2 install script - https://docs.rke2.io/install/airgap#rke2-installsh-script-install
mkdir -p /root/rke2-artifacts && cd /root/rke2-artifacts/
wget --continue "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2-images.linux-amd64.tar.zst"
wget --continue "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/rke2.linux-amd64.tar.gz"
wget --continue "https://github.com/rancher/rke2/releases/download/$INSTALL_RKE2_VERSION/sha256sum-amd64.txt"
curl --retry 3 --retry-connrefused -sfL https://get.rke2.io --output install.sh
cd /root/rke2-artifacts/ && chmod +x install.sh
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts ./install.sh
