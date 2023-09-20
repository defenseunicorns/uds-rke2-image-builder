#!/bin/bash

# If no bootstrap IP is provided then start RKE2 as single node/bootstrap
if [[ "${BOOTSTRAP_IP}" == "" ]]; then
    bootstrap_ip=$(ip route get $(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+') | grep -oP 'src \K\S+')
else
    bootstrap_ip=${BOOTSTRAP_IP}
fi

if [[ "${CLUSTER_SANS}" ]]; then
    echo "Passing SANs to RKE2 startup script: ${CLUSTER_SANS}"
    san_options="-T ${CLUSTER_SANS}"
fi

echo "Bootstrap node IP: $${bootstrap_ip}"

if [[ "${AGENT_NODE}" == "true" ]]; then
    ./root/rke2-startup.sh -t ${RKE2_JOIN_TOKEN} $${san_options} -s $${bootstrap_ip} -u ${DEFAULT_USER} -a
else
    ./root/rke2-startup.sh -t ${RKE2_JOIN_TOKEN} $${san_options} -s $${bootstrap_ip} -u ${DEFAULT_USER}
fi
