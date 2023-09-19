SHELL := /bin/bash

# Dirpaths for flavors
AWS_DIR := packer/aws

E2E_TEST_DIR := test/e2e

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

.PHONY: publish-ami-ubuntu
publish-ami-ubuntu: ## Build and Publish the AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "ubuntu_pro_token=$(ubuntu_pro_token)" --var-file=ubuntu.pkrvars.hcl .

.PHONY: publish-ami-rhel
publish-ami-rhel: ## Build and Publish the RHEL AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build --var-file=rhel.pkrvars.hcl .

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

######################
# Test Targets
######################

.PHONY: test-ami-ubuntu
test-ami-ubuntu: fmt-ami validate-ami-ubuntu build-ami-ubuntu ## fmt, validate, and build the AMI for AWS.

.PHONY: test-ami-rhel
test-ami-rhel: fmt-ami validate-ami-rhel build-ami-rhel ## fmt, validate, and build the AMI for AWS.

.PHONY: e2e-ubuntu
e2e-ubuntu: validate-ami-ubuntu publish-ami-ubuntu test-rke2-module teardown-rke2-module cleanup-ami

.PHONY: e2e-rhel
e2e-rhel: validate-ami-rhel publish-ami-rhel test-rke2-module teardown-rke2-module cleanup-ami

# Test AMI with Rancher AWS Terraform module
.PHONY: test-rke2-module
test-rke2-module:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	cd $(E2E_TEST_DIR)/rke2-module; \
	terraform init -force-copy \
		-backend-config="bucket=uds-ci-state-bucket" \
		-backend-config="key=tfstate/ci/install/$${SHA:0:7}-packer-$(DISTRO)-rke2-module.tfstate" \
		-backend-config="region=us-west-2" \
		-backend-config="dynamodb_table=uds-ci-state-dynamodb"; \
	terraform apply -var="ami_id=$${TEST_AMI_ID}" -auto-approve; \
	kubectl get nodes

.PHONY: teardown-rke2-module
teardown-rke2-module:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	cd $(E2E_TEST_DIR)/rke2-module; \
	terraform destroy -var="ami_id=$${TEST_AMI_ID}" -auto-approve

# Test AMI with baked in RKE2 startup script
.PHONY: test-rke2-start-script
test-rke2-start-script:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	cd $(E2E_TEST_DIR)/rke2-start-script; \
	terraform init -force-copy \
		-backend-config="bucket=uds-ci-state-bucket" \
		-backend-config="key=tfstate/ci/install/$${SHA:0:7}-packer-$(DISTRO)-rke2-startup-script.tfstate" \
		-backend-config="region=us-west-2"; \
	terraform apply -var="ami_id=$${TEST_AMI_ID}" -var-file="$(DISTRO).tfvars” -auto-approve

.PHONY: teardown-rke2-start-script
teardown-rke2-start-script:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	cd $(E2E_TEST_DIR)/rke2-start-script; \
	terraform destroy -var="ami_id=$${TEST_AMI_ID}" -var-file="$(DISTRO).tfvars” -auto-approve

# Grab generated SSH key from terraform outputs
.PHONY: get-ssh-key
get-ssh-key:
	cd $(E2E_TEST_DIR)/rke2-start-script; \
	terraform output -raw private_key

.PHONY: cleanup-ami
cleanup-ami:
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

######################
# Local testing in dev account
######################

# Test AMI with baked in RKE2 startup script in dev account
.PHONY: validate-rke2-start-script-dev
validate-rke2-start-script-dev:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	cd $(E2E_TEST_DIR)/rke2-start-script; \
	terraform init -force-copy \
		-backend-config="bucket=uds-dev-state-bucket" \
		-backend-config="key=tfstate/$$(openssl rand -hex 3)-packer-$(DISTRO)-rke2-startup-script.tfstate" \
		-backend-config="region=us-west-2"; \
	terraform validate

.PHONY: test-rke2-start-script-dev
test-rke2-start-script-dev:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	cd $(E2E_TEST_DIR)/rke2-start-script; \
	terraform init -force-copy \
		-backend-config="bucket=uds-dev-state-bucket" \
		-backend-config="key=tfstate/$$(openssl rand -hex 3)-packer-$(DISTRO)-rke2-startup-script.tfstate" \
		-backend-config="region=us-west-2"; \
	terraform apply -var="ami_id=$${TEST_AMI_ID}" -var="vpc_name=rke2-dev" -var="subnet_name=rke2-dev-public*" -var-file="$(DISTRO).tfvars" -auto-approve

.PHONY: teardown-rke2-start-script-dev
teardown-rke2-start-script-dev:
	TEST_AMI_ID=$$(jq -r '.builds[-1].artifact_id' $(AWS_DIR)/manifest.json | cut -d ":" -f2); \
	echo "TEST AMI: $${TEST_AMI_ID}"; \
	cd $(E2E_TEST_DIR)/rke2-start-script; \
	terraform destroy -var="ami_id=$${TEST_AMI_ID}" -var="vpc_name=rke2-dev" -var="subnet_name=rke2-dev-public*" -var-file="$(DISTRO).tfvars" -auto-approve
