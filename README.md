# UDS RKE2 Image Builder

This repo contains Packer code to produce STIG'd RKE2 images for various environments. Built images will have:
- Base OS (currently supporting RHEL 8 and Ubuntu 20.04)
- STIGs applied to the OS
- RKE2 pre-installed and airgap ready (all images pre-installed)

## Supported Builds

- AWS AMI: See [this directory](./packer/aws) and associated make targets with `make help | grep AWS`
- Nutanix Image: See [this directory](./packer/nutanix) and associated make targets with `make help | grep Nutanix`
