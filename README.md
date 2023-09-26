# UDS RKE2 Image Builder

This repo contains Packer code to produce STIG'd RKE2 images for various environments. Built images will have:
- Base OS (currently supporting RHEL 8 and Ubuntu 20.04)
- STIGs applied to the OS
- RKE2 pre-installed and airgap ready (all images pre-installed)

## Supported Builds

- AWS AMI: See [this directory](./packer/aws) and associated make targets with `make help | grep AWS`
- Nutanix Image: See [this directory](./packer/nutanix) and associated make targets with `make help | grep Nutanix`

## Local Testing

Packer targets should work locally or in CI. For testing the AMIs published locally with the rke2-cluster terraform module, the `test-cluster-dev`, `teardown-infra-dev`, and `cleanup-ami` make targets can be used.

Examples and info for each:

`make publish-ami-ubuntu` - Builds and publishes an Ubuntu AMI to your current configured AWS context

`make test-cluster-dev DISTRO="ubuntu"` - DISTRO should be set to match distro of AMI being used (currently should be either `rhel` or `ubuntu`). Grabs AMI ID from packer manifest from previous AWS packer build and uses it to deploy the rke2-cluster terraform module. After terraform apply completes, it then grabs the kubeconfig file from a cluster node that was deployed and saves it to ~/.kube/rke-config as well as adds an entry for the configured cluster hostname to the /etc/hosts file.

`make teardown-infra-dev DISTRO="ubuntu"` - DISTRO should be set to match distro of AMI being used (currently should be either `rhel` or `ubuntu`). Destroys all infrastructure deployed by test-cluster-dev target.

`make cleanup-ami` - Unregister AMI and cleanup snapshots associated with it

`make full-up DISTRO="ubuntu"` - DISTRO should be set to match distro of AMI being used (currently should be either `rhel` or `ubuntu`). Runs both the publish-ami and test-cluster-dev make targets

`make full-down DISTRO="ubuntu"` - DISTRO should be set to match distro of AMI being used (currently should be either `rhel` or `ubuntu`). Runs both the teardown-infra-dev and cleanup-ami make targets
