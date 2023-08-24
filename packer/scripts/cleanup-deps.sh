#!/bin/bash
# Cleanup dependencies and utils that shouldn't be in final image

# Detect distro. This works fine with only rhel and ubuntu in the list, but will not work as is if you need to distinguish ubuntu/debian or rhel/fedora
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

if [[ $DISTRO == "rhel" ]]; then
    yum remove unzip ansible -y
elif [[ $DISTRO == "ubuntu" ]]; then
    # Cleanup temp files and utils
    apt-get remove ansible unzip -y
    apt-get autoremove -y
else
    echo "$DISTRO not an expected distribution."
fi

cd && rm -rf /tmp/*
