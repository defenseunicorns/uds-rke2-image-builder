#!/bin/bash
# Cleanup dependencies and utils that shouldn't be in final image

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