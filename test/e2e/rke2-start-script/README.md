# RKE2 on AWS

Terraform for deploying AMIs built by uds-rke2-image-builder and testing the rke2-startup.sh script.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.16.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.test_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.test_node_nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_security_group.test_node_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.test_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_node"></a> [agent\_node](#input\_agent\_node) | Should RKE2 start as agent | `bool` | `false` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI to use for deployment, must have RKE2 pre-installed | `string` | n/a | yes |
| <a name="input_bootstrap_ip"></a> [bootstrap\_ip](#input\_bootstrap\_ip) | IP address of RKE2 bootstrap node | `string` | `""` | no |
| <a name="input_default_user"></a> [default\_user](#input\_default\_user) | Default user of AMI | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region to use for deployment | `string` | `"us-west-2"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key to attach to the EC2 | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to deploy into | `string` | `"vpc-0007fc0c033f08824"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->