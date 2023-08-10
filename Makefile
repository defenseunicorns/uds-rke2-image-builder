# Dirpaths for flavors
AWS_DIR := packer/aws

######################
# Builds + Tests
######################
.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "\nUsage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo

.PHONY: build-ami
build-ami: ## Build the AMI for AWS.
	@cd $(AWS_DIR) && packer init . && packer build -var "ubuntu_pro_token=$(ubuntu_pro_token)" .

.PHONY: test-ami
test-ami: fmt-validate-ami ## Test the AMI build for AWS.
	@cd $(AWS_DIR) && packer build -var "skip_create_ami=true" -var "ubuntu_pro_token=$(ubuntu_pro_token)" .

.PHONY: fmt-validate-ami
fmt-validate-ami: ## Run packer formatting and validation for the AWS AMI.
	@cd $(AWS_DIR) && packer fmt .
	@cd $(AWS_DIR) && packer init .
	@cd $(AWS_DIR) && packer validate .
