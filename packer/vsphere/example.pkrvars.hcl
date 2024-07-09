vsphere_username = "admin"
vsphere_password = "nicepassword"
vsphere_server = "my.vcenter.local"
CPUs = "4"
uds_datastore_name = "node_datastore"
vm_ip_cidr = "10.0.0.0/24"
network_adapters = [
  {
    network = "Management Network"
    network_card = "vmxnet3"
  },
  {
    network = "Private Network"
    network_card = "pvrdma"
  }
]
k8s_node_role = "worker"
