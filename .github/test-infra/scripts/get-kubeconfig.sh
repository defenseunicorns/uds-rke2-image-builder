#!/bin/bash

# Utility script that can be called from a uds task after tofu has deployed the e2e test module

echo "tofu version: $(tofu --version)"

# Get required outputs from tofu
tofu output -raw private_key > key.pem
chmod 600 key.pem

bootstrap_ip=$(tofu output -raw bootstrap_ip)
echo "bootstrap_ip: ${bootstrap_ip}"

node_user=$(tofu output -raw node_user)
echo "node_user: ${node_user}"

cluster_hostname=$(tofu output -raw cluster_hostname)
echo "cluster_hostname: ${cluster_hostname}"

# Try ssh up to 20 times waiting 15 seconds between tries
for i in $(seq 1 20); do
    echo "Waiting on cloud-init to finish running on cluster node"
    ssh -o StrictHostKeyChecking=no -i key.pem ${node_user}@${bootstrap_ip} "cloud-init status --wait" && break
    sleep 15
done

# Make sure .kube directory exists
mkdir -p ~/.kube

# Copy kubectl from cluster node
ssh -o StrictHostKeyChecking=no -i key.pem ${node_user}@${bootstrap_ip} "mkdir -p /home/${node_user}/.kube && sudo cp /etc/rancher/rke2/rke2.yaml /home/${node_user}/.kube/config && sudo chown ${node_user} /home/${node_user}/.kube/config"
scp -o StrictHostKeyChecking=no -i key.pem ${node_user}@${bootstrap_ip}:/home/${node_user}/.kube/config ~/.kube/rke2-config

# Replace the loopback address with the cluster hostname
sed -i "s/127.0.0.1/${bootstrap_ip}/g" ~/.kube/rke2-config
export KUBECONFIG=~/.kube/rke2-config

# find existing host record in the host file and save the line numbers
matches_in_hosts="$(grep -n $cluster_hostname /etc/hosts | cut -f1 -d:)"
host_entry="${bootstrap_ip} ${cluster_hostname}"

# Add or update /etc/hosts file record
if [ ! -z "$matches_in_hosts" ]
then
    echo "Updating existing hosts entry."
    # iterate over the line numbers on which matches were found
    while read -r line_number; do
        # replace the text of each line with the desired host entry
        sudo sed -i "${line_number}s/.*/${host_entry} /" /etc/hosts
    done <<< "$matches_in_hosts"
else
    echo "Adding new hosts entry."
    echo "$host_entry" | sudo tee -a /etc/hosts
fi
