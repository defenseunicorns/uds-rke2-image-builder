#!/bin/bash

cp /tmp/rke2-startup.sh /home/$default_user/rke2-startup.sh 
chmod +x /home/$default_user/rke2-startup.sh 
chown $default_user:$default_user /home/$default_user/rke2-startup.sh

cp -r /tmp/stig-configs /home/$default_user/stig-configs
chown -R $default_user:$default_user /home/$default_user/stig-configs
