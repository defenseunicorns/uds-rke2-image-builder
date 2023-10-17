SHELL := /bin/bash

# Dirpaths for flavors
AWS_DIR := packer/aws
NUTANIX_DIR := packer/nutanix

E2E_TEST_DIR := .github/test-infra

######################
# Make Targets
######################
.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "\nUsage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo

######################
# Packer Targets
######################

# AWS

.PHONY: publish-ami-ubuntu
publish-ami-ubuntu: ## Build and Publish the Ubuntu AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "ubuntu_pro_token=$(ubuntu_pro_token)" --var-file=ubuntu.pkrvars.hcl .

.PHONY: publish-ami-rhel
publish-ami-rhel: ## Build and Publish the RHEL AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build --var-file=rhel.pkrvars.hcl .

.PHONY: build-ami-ubuntu
build-ami-ubuntu: ## Build the Ubuntu AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "skip_create_ami=true" -var "ubuntu_pro_token=$(ubuntu_pro_token)" --var-file=ubuntu.pkrvars.hcl .

.PHONY: build-ami-rhel
build-ami-rhel: ## Build the RHEL AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "skip_create_ami=true" --var-file=rhel.pkrvars.hcl .

.PHONY: fmt-ami
fmt-ami: ## Run packer fmt for the AWS Ubuntu AMI.
	@cd $(AWS_DIR) && packer fmt .

.PHONY: validate-ami-ubuntu
validate-ami-ubuntu: ## Run packer validation for the AWS Ubuntu AMI.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer validate --var-file=ubuntu.pkrvars.hcl .

.PHONY: validate-ami-rhel
validate-ami-rhel: ## Run packer validation for the AWS RHEL AMI.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer validate --var-file=rhel.pkrvars.hcl .

# Nutanix

.PHONY: publish-nutanix
publish-nutanix: ## Build and Publish the Nutanix Image.
	@cd $(NUTANIX_DIR) && packer init .
	@cd $(NUTANIX_DIR) && packer build -var "ubuntu_pro_token=$(ubuntu_pro_token)" .

.PHONY: build-nutanix
build-nutanix: ## Build the Nutanix Image.
	@cd $(NUTANIX_DIR) && packer init .
	@cd $(NUTANIX_DIR) && packer build -var "image_delete=true" -var "ubuntu_pro_token=$(ubuntu_pro_token)" .

.PHONY: fmt-nutanix
fmt-nutanix: ## Run packer fmt for the Nutanix Image.
	@cd $(NUTANIX_DIR) && packer fmt .

.PHONY: validate-nutanix
validate-nutanix: ## Run packer validation for the Nutanix Image.
	@cd $(NUTANIX_DIR) && packer init .
	@cd $(NUTANIX_DIR) && packer validate .


######################
# Test Targets
######################

.PHONY: test-ami-ubuntu
test-ami-ubuntu: fmt-ami validate-ami-ubuntu build-ami-ubuntu ## fmt, validate, and build the Ubuntu AMI for AWS.

.PHONY: test-ami-rhel
test-ami-rhel: fmt-ami validate-ami-rhel build-ami-rhel ## fmt, validate, and build the RHEL AMI for AWS.

# Test AMI with baked in RKE2 startup script
.PHONY: test-cluster
test-cluster:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	ROOT_DIR=$$(pwd); \
	cd $(E2E_TEST_DIR)/rke2-cluster; \
	terraform init -force-copy \
		-backend-config="bucket=uds-ci-state-bucket" \
		-backend-config="key=tfstate/ci/install/$${SHA:0:7}-packer-$(DISTRO)-rke2-startup-script.tfstate" \
		-backend-config="region=us-west-2"; \
	terraform apply -var="ami_id=$${TEST_AMI_ID}" -var-file="$(DISTRO).tfvars" -auto-approve; \
	source $${ROOT_DIR}/$(E2E_TEST_DIR)/scripts/get-kubeconfig.sh; \
	kubectl wait --for=condition=Ready nodes --all --timeout=600s; \
	kubectl apply -f ../manifests/test.yaml; \
	kubectl wait --for=condition=Ready -n test pod/test-pod --timeout=60s

.PHONY: teardown-infra
teardown-infra:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	cd $(E2E_TEST_DIR)/rke2-cluster; \
	terraform destroy -var="ami_id=$${TEST_AMI_ID}" -var-file="$(DISTRO).tfvars" -auto-approve

.PHONY: cleanup-ami
cleanup-ami: ## Cleans up snapshots and AMI previously published
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	AMI_REGION=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f1); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	snapshot_ids=$$(aws ec2 describe-images --image-ids "$${TEST_AMI_ID}" --region $${AMI_REGION} | jq -r .Images[].BlockDeviceMappings[].Ebs.SnapshotId); \
	aws ec2 deregister-image --region $${AMI_REGION} --image-id $${TEST_AMI_ID}; \
	for snapshot in $${snapshot_ids}; do \
		if [[ $${snapshot} == snap* ]]; then \
			echo "Deleting snapshot: $${snapshot}"; \
			aws ec2 delete-snapshot --region $${AMI_REGION} --snapshot-id "$${snapshot}"; \
		fi \
	done
