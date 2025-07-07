#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# sysctl changes for UDS Core apps - (originally from https://docs-bigbang.dso.mil/latest/docs/prerequisites/os-preconfiguration/)
declare -A sysctl_settings
sysctl_settings["fs.nr_open"]=13181250
sysctl_settings["fs.inotify.max_user_instances"]=1024
sysctl_settings["fs.inotify.max_user_watches"]=1048576

# sysctl changes for UDS SWF apps
# GitLab Runner (Buildah) (note - this is a STIG finding but is n/a when running Linux containers: https://www.stigviewer.com/stig/red_hat_enterprise_linux_9/2023-09-13/finding/V-257816)
sysctl_settings["user.max_user_namespaces"]=30110

# SonarQube
sysctl_settings["vm.max_map_count"]=524288
sysctl_settings["fs.file-max"]=13181250

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

# cgroupsv2 for RKE2 + NeuVector
sed -i 's/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"systemd.unified_cgroup_hierarchy=1 /' /etc/default/grub
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
	unmanaged-devices=interface-name:flannel*;interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:vxlan-v6.calico;interface-name:wireguard.cali;interface-name:wg-v6.cali
	EOF
  systemctl reload NetworkManager
fi

# If present, disable services that interfere with cluster networking - https://docs.rke2.io/known_issues#firewalld-conflicts-with-default-networking
services_to_disable=("firewalld" "nm-cloud-setup" "nm-cloud-setup.timer")
for service in "${services_to_disable[@]}"; do
  if systemctl list-units --full -all | grep -Poi "$service" &>/dev/null; then
    systemctl stop "$service"
    systemctl disable "$service"
  fi
done
