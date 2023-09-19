output "private_key" {
  value     = tls_private_key.example_private_key.private_key_pem
  sensitive = true
}