#!/bin/bash

# Utility script that can be called from a uds task after terraform has deployed the e2e test module

echo "terraform version: $(terraform --version)"

# Get required outputs from terraform
terraform output -raw private_key > key.pem
chmod 600 key.pem

bootstrap_ip=$(terraform output -raw bootstrap_ip)
echo "bootstrap_ip: ${bootstrap_ip}"

node_user=$(terraform output -raw node_user)
echo "node_user: ${node_user}"

cluster_hostname=$(terraform output -raw cluster_hostname)
echo "cluster_hostname: ${cluster_hostname}"

# Try ssh up to 10 times waiting 15 seconds between tries
for i in $(seq 1 10); do
    echo "Waiting on cloud-init to finish running on cluster node"
    ssh -o StrictHostKeyChecking=no -i key.pem ${node_user}@${bootstrap_ip} "cloud-init status --wait" && break
    sleep 15
done

# Make sure .kube directory exists
mkdir -p ~/.kube

# Copy kubectl from cluster node
ssh -o StrictHostKeyChecking=no -i key.pem ${node_user}@${bootstrap_ip} "mkdir -p /home/${node_user}/.kube && sudo cp /etc/rancher/rke2/rke2.yaml /home/${node_user}/.kube/config && sudo chown ${node_user} /home/${node_user}/.kube/config"
scp -o StrictHostKeyChecking=no -i key.pem ${node_user}@${bootstrap_ip}:/home/${node_user}/.kube/config ~/.kube/config

# Replace the loopback address with the cluster hostname
sed -i "s/127.0.0.1/${bootstrap_ip}/g" ~/.kube/config
