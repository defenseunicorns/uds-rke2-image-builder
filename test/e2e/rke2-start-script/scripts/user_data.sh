#!/bin/bash

# If no bootstrap IP is provided then start RKE2 as single node/bootstrap
if [[ "${BOOTSTRAP_IP}" == "" ]]; then
    node_ip=$(ip route get $(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+') | grep -oP 'src \K\S+')
else
    node_ip=${BOOTSTRAP_IP}
fi

if [[ "${AGENT_NODE}" == "true" ]]; then
    ./rke2-startup.sh -t ${RKE2_JOIN_TOKEN} -s $${node_ip} -u ${DEFAULT_USER} -a
else
    ./rke2-startup.sh -t ${RKE2_JOIN_TOKEN} -s $${node_ip} -u ${DEFAULT_USER}
fi