# RKE2 Startup Helper Script

RKE2 provides excellent tooling to build an RKE2 cluster, but when considering the STIG guides for RKE2 and deploying via IaC there is additional runtime configuration required. The images built with packer in this repo bake a helper script into `/root/rke2-startup.sh` to simplify this process. While this script is certainly not required for startup it can simplify setup if used during cloud-init as part of your IaC. The script must be run as root due to RKE2's requirements for setup.

## Script Parameters

This script provides a number of parameters depending on your desired configuration:
- `-t <token>`: RKE2 uses a secret token to join nodes to the cluster securely. This can be generated with something like openssl to create a secure random string.
- `-s <join address>`: RKE2 initializes on a "bootstrap" node. The '-s' argument is the IP address or hostname of the bootstrap node or cluster control plane and is used by new nodes to join the cluster. When this is either unset or matches the IP of the host RKE2 is being started on, RKE2 will initialize as the bootstrap node.
- `-a`: RKE2 has server or agent nodes. Agent nodes are Kubernetes worker nodes and do not host critical services like etcd or control-plane deployments.
- `-T <dns address>`: By default cluster generated certificate is only valid for the loopback address and private IPs it can find on interfaces. When accessing cluster from a hostname or public IP, they need to be provided so they can be added to the cluster certificate.

## Recommended Usage

This script should be run on each node with a minimum of 3 server nodes for an HA setup, plus additional agent nodes as needed. Ideally you should also setup loadbalancing for server nodes (at minimum round-robin with DNS) so that a single node failure does not cause access issues.

An example setup is provided below:
- Node1: `/root/rke2-startup.sh -t <token> -s <node1_ip> -T <rke2_lb_address>`
- Node2: `/root/rke2-startup.sh -t <token> -s <rke2_lb_address> -T <rke2_dns_address>`
- Node3: `/root/rke2-startup.sh -t <token> -s <rke2_lb_address> -T <rke2_dns_address>`
- NodeN (agent nodes): `/root/rke2-startup.sh -t <token> -s <rke2_lb_address> -a`

## Additional RKE2 Links

- RKE2 Releases: https://github.com/rancher/rke2/releases
- Air-Gap Install: https://docs.rke2.io/install/airgap#tarball-method
- RKE2 Installation options: https://docs.rke2.io/install/methods
- RKE2 Configuration file: https://docs.rke2.io/install/configuration
- RKE2 High-availability: https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/kubernetes-cluster-setup/rke2-for-rancher
