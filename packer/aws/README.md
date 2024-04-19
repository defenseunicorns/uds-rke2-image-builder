# AWS AMI Builds

This folder contains the Packer code necessary to build STIG'd RKE2 AMIs, with support for RHEL 8 and Ubuntu 20.04 base images.

## Prerequisites

You must have your local AWS context configured (`aws sts get-caller-identity` should show your user).

You must choose a base image to build off of (`ubuntu.pkrvars.hcl` and `rhel.pkrvars.hcl` have examples that may be available in your environment).

## Setting up Variables

To build an AMI you typically only need a few variables. All available variable is described in the `variables.pkr.hcl` file and the most common are included for reference here as well:
- `ami_name`: Name to use for the final AMI build
- `base_ami_name`: Name of the base AMI to build off of
- `ssh_username`: Default user in the base AMI to use for building

## Building the Image

Assuming you have modified the variables as needed in the `ubuntu.pkrvars.hcl` or `rhel.pkrvars.hcl` file, you should be able to use the below [`uds`](https://github.com/defenseunicorns/uds-cli/blob/main/docs/runner.md) tasks for building the AMI and publishing to your active AWS environment:

```console
# Build the image using the ubuntu variables file
uds run publish-ami-ubuntu

# Build the image using the RHEL variables file
uds run publish-ami-rhel
```

## Using the Image

Once your image is built and "published" you can spin up an EC2 instance using it. One option for usage is to leverage the included RKE2 startup script to simplify cluster creation during cloud-init. Additional details on how to use the script can be seen in this [document](./docs/rke2-startup.md).
