# Image Builder Steps

The approach taken in this repo for image builds is meant to be the simplest path to get to a secure, minimal image with all RKE2 dependencies baked in, ready for the airgap. Wherever possible we leverage existing/upstream tooling so that we are not reinventing processes that require maintenance and diverge from the upstream.

This document outlines the approach taken for each of the core pieces built into the image.

## Dependency Installation/Cleanup

The first step of each image build involves installing any tooling necessary for the rest of the build process. This tooling is removed where possible at the end of the build process to ensure we are maintaining a minimal image. For RHEL distros the RKE2 SELinux RPM is installed to meet the prerequisites of RKE2.

As necessary installation/cleanup have branching logic to handle different package managers for different operating systems (ex: yum vs apt-get).

## OS STIG-ing

The [OS STIG script](../packer/scripts/os-stig.sh) leverages Ansible provided by DISA as part of their [automation content](https://public.cyber.mil/stigs/supplemental-automation-content/).

Leveraging this automation ensures that we stay as close to the source of the STIG as possible, and do not have to implement all the STIG fixes/checks ourselves.

The one piece not implemented in the Ansible STIG content is the enabling/installation of FIPS packages. Lightweight logic has been added to enable FIPS (note that FIPS on Ubuntu requires a subscription). For RHEL it is ideal to start with a base image that is FIPS enabled to ensure full FIPS compliance.

## RKE2 Install

The [RKE2 Install script](../packer/scripts/rke2-install.sh) installs RKE2, suitable for both server and agent nodes, following the upstream [RKE2 airgapped install guide](https://docs.rke2.io/install/airgap). The basic steps involved in our current script involve:
- Staging image tarballs: Image tarballs are downloaded and placed in the correct location for usage in an airgap (see [here](https://docs.rke2.io/install/airgap#tarball-method))
- Run the RKE2 install script from upstream: This is pulled directly from RKE2 docs [here](https://docs.rke2.io/install/airgap#rke2-installsh-script-install)

## OS Preparation

The [OS Preparation script](../packer/scripts/os-prep.sh) changes a number of things on the base OS to ensure smooth operation of RKE2 and UDS pieces running on top such as [DUBBD](https://github.com/defenseunicorns/uds-package-dubbd). Requirements were pulled from upstream documentation:
- [RKE2 Networking (iptables) requirements](https://docs.rke2.io/install/requirements#networking)
- Big Bang sysctl/SELinux requirements: [general requirements](https://docs-bigbang.dso.mil/latest/docs/prerequisites/os-preconfiguration/) and [logging specific requirements](https://docs-bigbang.dso.mil/latest/packages/fluentbit/docs/TROUBLESHOOTING/?h=fs.inotify.max_user_watches%2F#Too-many-open-files)
- Handling prerequisite requirements: Modifying network manager and disabling services that conflict with cluster networking (see [this](https://docs.rke2.io/known_issues#firewalld-conflicts-with-default-networking) and [this](https://docs.rke2.io/known_issues#networkmanager))

While these commands could be run at startup (via cloud-init or similar), configuration at build-time ensures that they are not forgotten and allows us to keep the startup process simpler.

## RKE2 STIG Helpers

The final portion of the build copies a few files into the image and ensures they have proper ownership for usage at runtime. The [RKE2 STIG](https://www.stigviewer.com/stig/rancher_government_solutions_rke2/2022-10-13/) is the basis for these files. The files added are:
- An audit policy adhering to [this STIG rule](https://www.stigviewer.com/stig/rancher_government_solutions_rke2/2022-10-13/finding/V-254555)
- An RKE2 config file pre-configured to meet STIG rules (note that some STIG rules are met by default with RKE2 and not included in this configuration explicitly)
- A default pod security config - this allows full privileges for running pods and is added with the expectation that a policy enforcement engine like Kyverno or Gatekeeper is being used to restrict the same things, with exceptions as necessary
- A helper script for RKE2 startup - while RKE2 can certainly be run without this, this script can be used to add the RKE2 join address, token, and other properties to the RKE2 config file. It also corrects file permissions according to the STIG guide for files that do not exist until RKE2 startup has occurred.

Additionally the etcd user and sysctl config are added for RKE2. This follows the process documented in the [RKE2 CIS Hardening guide](https://docs.rke2.io/security/hardening_guide#ensure-etcd-is-configured-properly).
