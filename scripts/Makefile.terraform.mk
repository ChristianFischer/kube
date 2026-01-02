KUBECTL := kubectl
TERRAFORM := terraform -chdir=terraform
KUBERNETES_MANIFEST_FILES := $(shell find ./manifests -type f -name "*.yml")
KUBERNETES_HELM_FILES := $(shell find ./helm -type f -name "*.yaml")
TERRAFORM_TF_FILES := $(shell find ./terraform -type f -name "*.tf")
TERRAFORM_INIT_MARKER := terraform/.terraform/.init.timestamp
TERRAFORM_PLAN_FILENAME := rpcloud.tfplan
TERRAFORM_PLAN_FILE := terraform/$(TERRAFORM_PLAN_FILENAME)


$(TERRAFORM_INIT_MARKER): $(TERRAFORM_TF_FILES) scripts/Makefile.terraform.mk
	# Ensure the namespace is created, where terraform will store the state.
	$(KUBECTL) create namespace terraform-state --dry-run=client -o yaml | $(KUBECTL) apply -f -

	$(TERRAFORM) init
	@touch $(TERRAFORM_INIT_MARKER)

terraform-init: $(TERRAFORM_INIT_MARKER)


terraform-state-pull:
	$(TERRAFORM) state pull > terraform/terraform.tfstate


$(TERRAFORM_PLAN_FILE): $(TERRAFORM_INIT_MARKER) $(TERRAFORM_TF_FILES) $(KUBERNETES_MANIFEST_FILES) $(KUBERNETES_HELM_FILES) scripts/Makefile.terraform.mk
	$(TERRAFORM) plan -out $(TERRAFORM_PLAN_FILENAME)

terraform-plan-force: $(TERRAFORM_PLAN_FILE)
	$(TERRAFORM) plan -out $(TERRAFORM_PLAN_FILENAME)

terraform-plan: $(TERRAFORM_PLAN_FILE)


terraform-apply: $(TERRAFORM_PLAN_FILE)
	$(TERRAFORM) apply $(TERRAFORM_PLAN_FILENAME)
	$(TERRAFORM) state pull > terraform/terraform.tfstate
