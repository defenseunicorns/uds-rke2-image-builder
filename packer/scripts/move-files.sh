#!/bin/bash

cp /tmp/rke2-startup.sh /root/rke2-startup.sh 
chmod +x /root/rke2-startup.sh 
chown $default_user:$default_user /root/rke2-startup.sh

cp -r /tmp/stig-configs /root/stig-configs
chown -R $default_user:$default_user /root/stig-configs
