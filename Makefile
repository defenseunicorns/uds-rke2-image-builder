SHELL := /bin/bash

# Dirpaths for flavors
AWS_DIR := packer/aws

TEST_TF_DIR := test/e2e/rke2

######################
# Make Targets
######################
.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "\nUsage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo

.PHONY: publish-ami-ubuntu
publish-ami-ubuntu: ## Build and Publish the AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "ubuntu_pro_token=$(ubuntu_pro_token)" --var-file=ubuntu.pkrvars.hcl .

.PHONY: publish-ami-rhel
publish-ami-rhel: ## Build and Publish the RHEL AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build --var-file=rhel.pkrvars.hcl .

.PHONY: test-ami-ubuntu
test-ami-ubuntu: fmt-ami validate-ami-ubuntu build-ami-ubuntu ## fmt, validate, and build the AMI for AWS.

.PHONY: test-ami-rhel
test-ami-rhel: fmt-ami validate-ami-rhel build-ami-rhel ## fmt, validate, and build the AMI for AWS.

.PHONY: e2e-ubuntu
e2e-ubuntu: validate-ami-ubuntu publish-ami-ubuntu
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	cd $(TEST_TF_DIR); \
	terraform init -force-copy \
		-backend-config="bucket=uds-ci-state-bucket" \
		-backend-config="key=tfstate/ci/install/$${SHA:0:7}-packer-ubuntu-rke2.tfstate" \
		-backend-config="region=us-west-2" \
		-backend-config="dynamodb_table=uds-ci-state-dynamodb"; \
	terraform apply -var="ami_id=$${TEST_AMI_ID}" -auto-approve; \
	kubectl get nodes; \
	terraform destroy -var="ami_id=$${TEST_AMI_ID}" -auto-approve; \
	snapshot_ids=$$(aws ec2 describe-images --image-ids "$${TEST_AMI_ID}" | jq -r .Images[].BlockDeviceMappings[].Ebs.SnapshotId); \
	aws ec2 deregister-image --image-id $${TEST_AMI_ID}; \
	for snapshot in $${snapshot_ids}; do \
		echo "$${snapshot}"; \
		aws ec2 delete-snapshot --snapshot-id "$${snapshot}"; \
	done

.PHONY: e2e-rhel
e2e-rhel: validate-ami-rhel publish-ami-rhel
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	cd $(TEST_TF_DIR); \
	terraform init -force-copy \
		-backend-config="bucket=uds-ci-state-bucket" \
		-backend-config="key=tfstate/ci/install/$${SHA:0:7}-packer-rhel-rke2.tfstate" \
		-backend-config="region=us-west-2" \
		-backend-config="dynamodb_table=uds-ci-state-dynamodb"; \
	terraform apply -var="ami_id=$${TEST_AMI_ID}" -auto-approve; \
	kubectl get nodes; \
	terraform destroy -var="ami_id=$${TEST_AMI_ID}" -auto-approve; \
	snapshot_ids=$$(aws ec2 describe-images --image-ids "$${TEST_AMI_ID}" | jq -r .Images[].BlockDeviceMappings[].Ebs.SnapshotId); \
	aws ec2 deregister-image --image-id $${TEST_AMI_ID}; \
	for snapshot in $${snapshot_ids}; do \
		echo "$${snapshot}"; \
		aws ec2 delete-snapshot --snapshot-id "$${snapshot}"; \
	done

.PHONY: build-ami-ubuntu
build-ami-ubuntu: ## Build the AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "skip_create_ami=true" -var "ubuntu_pro_token=$(ubuntu_pro_token)" --var-file=ubuntu.pkrvars.hcl .

.PHONY: build-ami-rhel
build-ami-rhel: ## Build the RHEL AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "skip_create_ami=true" --var-file=rhel.pkrvars.hcl .

.PHONY: fmt-ami
fmt-ami: ## Run packer fmt for the AWS AMI.
	@cd $(AWS_DIR) && packer fmt .

.PHONY: validate-ami-ubuntu
validate-ami-ubuntu: ## Run packer validation for the AWS AMI.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer validate --var-file=ubuntu.pkrvars.hcl .

.PHONY: validate-ami-rhel
validate-ami-rhel: ## Run packer validation for the AWS RHEL AMI.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer validate --var-file=rhel.pkrvars.hcl .
