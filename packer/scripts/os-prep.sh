#!/bin/bash

# Detect distro. This works fine with only rhel and ubuntu in the list, but will not work as is if you need to distinguish ubuntu/debian or rhel/fedora
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

echo "Performing OS prep necessary for DUBBD on RKE2..."

# iptables for RKE2
if [[ $DISTRO == "rhel" ]]; then
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 2379 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 2380 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 9345 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 6443 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 udp dport 8472 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 10250 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 30000-32767 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 4240 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 179 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 udp dport 4789 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 5473 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 9098 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 tcp dport 9099 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 udp dport 51820 ct state new accept
  nft add rule ip filter input ip saddr 0.0.0.0/0 udp dport 51821 ct state new accept
  nft add rule ip filter input ip protocol icmp icmp type echo-request ct state new,established,related accept
  nft add rule ip filter output ip protocol icmp icmp type echo-reply ct state established,related accept
  nft -s list ruleset > /etc/nftables/rules.v4.nft
  echo "include \"/etc/nftables/rules.v4.nft\"" >> /etc/sysconfig/nftables.conf
  systemctl enable nftables
elif [[ $DISTRO == "ubuntu" ]]; then
  iptables -A INPUT -p tcp -m tcp --dport 2379 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 2380 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 9345 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 6443 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p udp -m udp --dport 8472 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 10250 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 30000:32767 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 4240 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 179 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p udp -m udp --dport 4789 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 5473 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 9098 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 9099 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p udp -m udp --dport 51820 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p udp -m udp --dport 51821 -m state --state NEW -j ACCEPT
  iptables -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT
  iptables-save > /etc/iptables/rules.v4
fi

# ulimit and sysctl changes for DUBBD
echo "* soft nofile 13181250" >> /etc/security/limits.d/ulimits.conf
echo "* hard nofile 13181250" >> /etc/security/limits.d/ulimits.conf
echo "* soft nproc  13181250" >> /etc/security/limits.d/ulimits.conf
echo "* hard nproc  13181250" >> /etc/security/limits.d/ulimits.conf
sysctl -w vm.max_map_count=524288
echo "vm.max_map_count=524288" > /etc/sysctl.d/vm-max_map_count.conf
sysctl -w fs.nr_open=13181252
echo "fs.nr_open=13181252" > /etc/sysctl.d/fs-nr_open.conf
sysctl -w fs.file-max=13181250
echo "fs.file-max=13181250" > /etc/sysctl.d/fs-file-max.conf
echo "fs.inotify.max_user_instances=1024" > /etc/sysctl.d/fs-inotify-max_user_instances.conf
sysctl -w fs.inotify.max_user_instances=1024
echo "fs.inotify.max_user_watches=1048576" > /etc/sysctl.d/fs-inotify-max_user_watches.conf
sysctl -w fs.inotify.max_user_watches=1048576
echo "vm.overcommit_memory=1" >> /etc/sysctl.d/90-kubelet.conf
sysctl -w vm.overcommit_memory=1
echo "kernel.panic=10" >> /etc/sysctl.d/90-kubelet.conf
sysctl -w kernel.panic=10
echo "kernel.panic_on_oops=1" >> /etc/sysctl.d/90-kubelet.conf
sysctl -w kernel.panic_on_oops=1
sysctl -p

# modprobes for Istio
modprobe br_netfilter
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
echo "br_netfilter" >> /etc/modules-load.d/istio-iptables.conf
echo "xt_REDIRECT" >> /etc/modules-load.d/istio-iptables.conf
echo "xt_owner" >> /etc/modules-load.d/istio-iptables.conf
echo "xt_statistic" >> /etc/modules-load.d/istio-iptables.conf

# cgroupsv2 for RKE2 + NeuVector
sed -i 's/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"systemd.unified_cgroup_hierarchy=1/' /etc/default/grub

BOOT_TYPE=$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)

if [[ $DISTRO == "rhel" ]]; then
    if [[ $BOOT_TYPE == "BIOS" ]]; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
    else
        grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
    fi
elif [[ $DISTRO == "ubuntu" ]]; then
    update-grub
fi
