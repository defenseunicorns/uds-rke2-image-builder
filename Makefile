# Dirpaths for flavors
AWS_DIR := packer/aws

######################
# Make Targets
######################
.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "\nUsage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo

.PHONY: publish-ami
publish-ami: ## Build and Publish the AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "ubuntu_pro_token=$(ubuntu_pro_token)" .

.PHONY: publish-ami-rhel
publish-ami-rhel: ## Build and Publish the RHEL AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build --var-file=rhel.pkrvars.hcl .

.PHONY: test-ami
test-ami: fmt-ami validate-ami build-ami ## fmt, validate, and build the AMI for AWS.

.PHONY: build-ami
build-ami: ## Build the AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "skip_create_ami=true" -var "ubuntu_pro_token=$(ubuntu_pro_token)" .

.PHONY: build-ami-rhel
build-ami-rhel: ## Build the RHEL AMI for AWS.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer build -var "skip_create_ami=true" --var-file=rhel.pkrvars.hcl .

.PHONY: fmt-ami
fmt-ami: ## Run packer fmt for the AWS AMI.
	@cd $(AWS_DIR) && packer fmt .

.PHONY: validate-ami
validate-ami: ## Run packer validation for the AWS AMI.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer validate .

.PHONY: validate-ami-rhel
validate-ami-rhel: ## Run packer validation for the AWS RHEL AMI.
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer validate --var-file=rhel.pkrvars.hcl .
