# UDS RKE2 Image Builder

This repo contains Packer code to produce STIG'd RKE2 images for various environments. Built images will have:
- Base OS (currently supporting RHEL and Ubuntu)
- STIGs applied to the OS
- RKE2 pre-installed, STIG'd, and airgap ready (all images pre-installed)

For more details on what happens during the image building process see [this doc](./docs/builder-steps.md).

## Supported Builds and Usage

This repo currently supports the following target environments:
- AWS AMI: See [this doc](./packer/aws/README.md) for usage
- Nutanix Image: See [this doc](./packer/nutanix/README.md) for usage

Note that for other target environments you may be able to build with one of these and export to your desired format.

## Local Testing

Currently this repo does not support completely local development, you must have an AWS or Nutanix environment (depending on your target deployment).
