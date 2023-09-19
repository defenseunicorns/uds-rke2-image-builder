# RKE2 on AWS

Terraform for deploying AMIs built by uds-rke2-image-builder and testing the rke2-startup.sh script. Recommended to configure a file named like `<yourname>.auto.pkrvars.hcl` to set variable overrides for local testing. This can be used to change node counts as well as add your local IP to the ingress rules for the cluster SG so you can connect to the cluster after it is up.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.test_agent_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.test_bootstrap_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.test_control_plane_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.example_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.test_node_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.rke2_join_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [tls_private_key.example_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_subnet.test_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_node_count"></a> [agent\_node\_count](#input\_agent\_node\_count) | How many agent nodes to spin up | `number` | `0` | no |
| <a name="input_allowed_in_cidrs"></a> [allowed\_in\_cidrs](#input\_allowed\_in\_cidrs) | Optional list of CIDRs that can connect to the cluster in addition to CIDR of VPC cluster is deployed to | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI to use for deployment, must have RKE2 pre-installed | `string` | n/a | yes |
| <a name="input_control_plane_node_count"></a> [control\_plane\_node\_count](#input\_control\_plane\_node\_count) | How many control plane nodes to spin up | `number` | `1` | no |
| <a name="input_default_user"></a> [default\_user](#input\_default\_user) | Default user of AMI | `string` | n/a | yes |
| <a name="input_os_distro"></a> [os\_distro](#input\_os\_distro) | OS distribution used to distinguish test infra based on which test created it | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region to use for deployment | `string` | `"us-west-2"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | What to name generated SSH key pair in AWS | `string` | n/a | yes |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Name of subnet to use for testing. Can use a wildcard as long as it only matches one subnet per az. | `string` | `"uds-ci-commercial-842d-public*"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | VPC ID to deploy into | `string` | `"uds-ci-commercial-842d"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_key"></a> [private\_key](#output\_private\_key) | n/a |
<!-- END_TF_DOCS -->