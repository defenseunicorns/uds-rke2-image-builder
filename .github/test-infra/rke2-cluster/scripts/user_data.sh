#!/bin/bash

# If no bootstrap IP is provided then start RKE2 as single node/bootstrap
if [[ "${BOOTSTRAP_IP}" == "" ]]; then
    bootstrap_ip=$(ip route get $(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+') | grep -oP 'src \K\S+')
else
    bootstrap_ip=${BOOTSTRAP_IP}
fi

if [[ "${CLUSTER_SANS}" ]]; then
    echo "Passing SANs to RKE2 startup script: ${CLUSTER_SANS}"
    public_ipv4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
    # Use array to properly handle cluster_sans containing multiple values
    san_options=(-T "$${public_ipv4} ${CLUSTER_SANS}")
fi

if [[ "${AGENT_NODE}" == "true" ]]; then
    /root/rke2-startup.sh -t ${RKE2_JOIN_TOKEN} -s $${bootstrap_ip} -a
else
    /root/rke2-startup.sh -t ${RKE2_JOIN_TOKEN} -s $${bootstrap_ip}
fi
