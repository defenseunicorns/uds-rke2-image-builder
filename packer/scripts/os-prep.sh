#!/bin/bash
set -e

# Helper functions for adding firewall rules
add_rule_nft() {
  local protocol="$1"
  local port="$2"
  nft add rule ip filter input ip saddr 0.0.0.0/0 "$protocol" dport "$port" ct state new accept
}

add_rule_ipt() {
  local protocol="$1"
  local port="${2/-/:}" # Replace the hyphen with a colon for iptables if needed
  iptables -A INPUT -p "$protocol" --dport "$port" -m state --state NEW -j ACCEPT
}

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Port requirements for RKE2 based on https://docs.rke2.io/install/requirements#networking
tcp_ports=("2379" "2380" "9345" "6443" "10250" "30000-32767" "4240" "179" "5473" "9098" "9099")
udp_ports=("8472" "4789" "51820" "51821")

# Add firewall rules per distro
if [[ $DISTRO == "rhel" ]]; then
  nft add table ip filter
  nft add chain ip filter input { type filter hook input priority 0\; }
  nft add chain ip filter output { type filter hook output priority 0\; }
  for port in "${tcp_ports[@]}"; do
    add_rule_nft tcp "$port"
  done
  for port in "${udp_ports[@]}"; do
    add_rule_nft udp "$port"
  done
  # Add ICMP rules
  nft add rule ip filter input ip protocol icmp icmp type echo-request ct state new,established,related accept
  nft add rule ip filter output ip protocol icmp icmp type echo-reply ct state established,related accept
  # Persist rules on restart
  nft -s list ruleset > /etc/nftables/rules.v4.nft
  echo "include \"/etc/nftables/rules.v4.nft\"" >> /etc/sysconfig/nftables.conf
  systemctl enable nftables
elif [[ $DISTRO == "ubuntu" ]]; then
  for port in "${tcp_ports[@]}"; do
    add_rule_ipt tcp "$port"
  done
  for port in "${udp_ports[@]}"; do
    add_rule_ipt udp "$port"
  done
  # Add ICMP rules
  iptables -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT
  # Persist rules on restart
  iptables-save > /etc/iptables/rules.v4
fi

# sysctl changes for Big Bang apps - https://docs-bigbang.dso.mil/latest/docs/prerequisites/os-preconfiguration/
declare -A sysctl_settings
sysctl_settings["vm.max_map_count"]=524288
sysctl_settings["fs.nr_open"]=13181250
sysctl_settings["fs.file-max"]=13181250
sysctl_settings["fs.inotify.max_user_instances"]=1024
sysctl_settings["fs.inotify.max_user_watches"]=1048576
sysctl_settings["vm.overcommit_memory"]=1
sysctl_settings["kernel.panic"]=10
sysctl_settings["kernel.panic_on_oops"]=1
for key in "${!sysctl_settings[@]}"; do
  value="${sysctl_settings[$key]}"
  sysctl -w "$key=$value"
  echo "$key=$value" > "/etc/sysctl.d/$key.conf"
done
sysctl -p

# Kernel Modules for Istio - https://istio.io/latest/docs/setup/platform-setup/prerequisites/
modules=("br_netfilter" "xt_REDIRECT" "xt_owner" "xt_statistic" "iptable_mangle" "iptable_nat" "xt_conntrack" "xt_tcpudp")
for module in "${modules[@]}"; do
  modprobe "$module"
  echo "$module" >> "/etc/modules-load.d/istio-modules.conf"
done

# cgroupsv2 for RKE2 + NeuVector - https://docs.rke2.io/known_issues#control-groups-v2
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

# If Network Manager is being used configure it to ignore calico/flannel network interfaces - https://docs.rke2.io/known_issues#networkmanager
if systemctl list-units --full | grep -Poi "NetworkManager.service" &>/dev/null; then
  # Indent with tabs to prevent spaces in heredoc output
	cat <<- EOF > /etc/NetworkManager/conf.d/rke2-canal.conf
	[keyfile]
	unmanaged-devices=interface-name:cali*;interface-name:flannel*
	EOF
  systemctl reload NetworkManager
fi

# If present, disable services that interfere with cluster networking - https://docs.rke2.io/known_issues#firewalld-conflicts-with-default-networking
services_to_disable=("firewalld" "nm-cloud-setup" "nm-cloud-setup.timer")
for service in "${services_to_disable[@]}"; do
  if systemctl list-units --full | grep -Poi "$service.service" &>/dev/null; then
    systemctl disable "$service.service"
  fi
done
