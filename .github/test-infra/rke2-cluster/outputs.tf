output "private_key" {
  value     = tls_private_key.example_private_key.private_key_pem
  description = "Generated SSH private key that can be used to connect to a cluster node."
  sensitive = true
}

output "bootstrap_ip" {
  value = aws_instance.test_bootstrap_node.public_ip
  description = "Public IP address of the bootstrap control plane node."
}

output "node_user" {
  value = var.default_user
  description = "User to use when connecting to a cluster node."
}

output "cluster_hostname" {
  value = var.cluster_hostname
  description = "Hostname used to connect to cluster."
}
