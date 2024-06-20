lang en_US
keyboard --xlayouts='us'
timezone America/New_York --utc
rootpw $2b$10$khnKZoBJRQYDKnIWRcxtAO.o9.LRo9ELHAFYpTM/k0grVP7yFoABm --iscrypted --allow-ssh # default password is changeme
reboot
text
cdrom
eula --agreed
bootloader --append="rhgb quiet crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M"
zerombr
clearpart --all --initlabel
autopart
network --bootproto=dhcp
skipx
firstboot --disable
selinux --enforcing
firewall --enabled --ssh
%packages
@^minimal-environment
@network-tools
@hardware-monitoring
@standard
%end

reboot --eject
