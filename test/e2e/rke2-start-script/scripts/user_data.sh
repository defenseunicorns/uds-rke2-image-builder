#!/bin/bash

# If no bootstrap IP is provided then start RKE2 as single node/bootstrap
if [[ "${BOOTSTRAP_IP}" == "" ]]; then
    bootstrap_ip=$(ip route get $(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+') | grep -oP 'src \K\S+')
else
    bootstrap_ip=${BOOTSTRAP_IP}
fi

echo "Bootstrap node IP: $${bootstrap_ip}"

if [[ "${AGENT_NODE}" == "true" ]]; then
    ./home/${DEFAULT_USER}/rke2-startup.sh -t ${RKE2_JOIN_TOKEN} -s $${bootstrap_ip} -u ${DEFAULT_USER} -a
else
    ./home/${DEFAULT_USER}/rke2-startup.sh -t ${RKE2_JOIN_TOKEN} -s $${bootstrap_ip} -u ${DEFAULT_USER}
fi