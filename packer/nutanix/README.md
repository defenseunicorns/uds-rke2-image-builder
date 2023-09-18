# Nutanix Image Builds

This folder contains the Packer code necessary to build STIG'd RKE2 disk images on Nutanix, with support for RHEL 8 and Ubuntu 20.04 base images.

## Prerequisites

You must have Prism Central setup for your cluster(s).

You must already have your chosen base image(s) imported into Prism Central as a DISK image. You should be able to pull a "cloud image" from your OS provider, typically in a `.img` or `.qcow2` format. Common locations to pull these from:
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/focal/)
- [RHEL Cloud Image Builder](https://console.redhat.com/insights/image-builder) will build a "Virtualization - Guest image (.qcow2)" with your license attached. Ensure that Ansible automation platform repository is added to your [activation key](https://console.redhat.com/insights/connector/activation-keys) (ex: `ansible-automation-platform-2.4-for-rhel-8-x86_64-rpms`).

## Setting up Variables

To build on a Nutanix cluster you need to setup variables to point to your cluster and base image. An example variable file is provided in `example.pkrvars.hcl`. It is recommended to make a copy of this file and name it as `<yourname>.auto.pkrvars.hcl` so that it is automatically pulled in when running the make targets. Each variable is described in `variables.pkr.hcl` file and the most common are included for reference here as well:
- `nutanix_username`: Username for Prism Central
- `nutanix_password`: Password for Prism Central
- `nutanix_endpoint`: Endpoint (URL/IP) for Prism Central
- `nutanix_cluster`: Name of cluster to use for Packer build VM
- `nutanix_subnet`: Name of subnet in cluster to use for Packer build VM
- `image_delete`: Build, but delete the final image rather than saving on Prism Central
- `output_image_name`: Name of the output image, will have a timestamp appended
- `base_image_name`: Name of your base image in Prism Central

There are additional variables available as well that you may want to use in some cases.

## Building the Image

Assuming you have setup your variables in a `.auto.pkrvars.hcl` file, you should be able to use the below `make` targets for building the image and publishing to your active Nutanix environment:

```console
# Build the image using your variables file
make publish-nutanix

# Build the image with an override to force image_delete=true
make build-nutanix
```

## Using the Image

Once your image is built and "published" you can spin up a VM using it. Attach a disk, set to clone from the image you created, and resize it accordingly to your needs for the root disk. You will also likely want to use cloud-init for a few things:
- Setup an initial user (no default user exists in these built images): See [here](./cloud-config.yaml) for a basic example adding a user `packer` with the password `builder`.
- Set a unique hostname (default will likely be `ubuntu` on Ubuntu and `localhost` on RHEL): See [here](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#set-hostname) for example formatting to add to your cloud-init.
