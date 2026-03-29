.PHONY: help init plan apply destroy fmt lint test clean tf-init tf-plan tf-apply

# Default target
.DEFAULT_GOAL := help

# Variables
TERRAFORM := terraform
KUBECTL := kubectl
HELM := helm
ARGOCD := argocd

help:  ## Show this help message
	@echo "Terraform Kubernetes GitOps Platform - Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ====================
# Terraform Commands
# ====================

tf-init:  ## Initialize Terraform in infrastructure directory
	@echo "Initializing Terraform..."
	cd infrastructure && $(TERRAFORM) init -reconfigure

tf-plan: tf-init  ## Run terraform plan
	@echo "Running Terraform plan..."
	cd infrastructure && $(TERRAFORM) plan -var-file=terraform.tfvars

tf-apply: tf-init  ## Run terraform apply (auto-approve)
	@echo "Applying Terraform configuration..."
	cd infrastructure && $(TERRAFORM) apply -var-file=terraform.tfvars -auto-approve

tf-destroy: tf-init  ## Destroy all Terraform resources
	@echo "Destroying Terraform infrastructure..."
	cd infrastructure && $(TERRAFORM) destroy -var-file=terraform.tfvars -auto-approve

init: tf-init  ## Alias for tf-init

plan: tf-plan  ## Alias for tf-plan

apply: tf-apply  ## Alias for tf-apply

destroy: tf-destroy  ## Alias for tf-destroy

fmt:  ## Format Terraform files
	@echo "Formatting Terraform files..."
	$(TERRAFORM) fmt -recursive infrastructure/
	@echo "Formatting Kubernetes manifests..."
	find kubernetes/ -name "*.yaml" -exec yq eval --inplace '.' {} \; 2>/dev/null || true
	find helm-charts/ -name "*.yaml" -exec yq eval --inplace '.' {} \; 2>/dev/null || true

lint:  ## Lint Terraform and K8s manifests
	@echo "Linting Terraform..."
	cd infrastructure && $(TERRAFORM) validate
	@echo "Linting Kubernetes YAML..."
	@which yamllint > /dev/null && yamllint kubernetes/ helm-charts/ namespaces/ || echo "yamllint not installed, skipping"
	@which kubeval > /dev/null && find kubernetes/ -name "*.yaml" -exec kubeval {} \; || echo "kubeval not installed, skipping"

test:  ## Run all tests
	@echo "Running tests..."
	@$(MAKE) lint
	@$(MAKE) tf-init
	@cd infrastructure && $(TERRAFORM) validate && echo "Terraform validation passed!"
	@echo "All tests passed!"

# ====================
# Kubernetes Commands
# ====================

kube-apply-dev:  ## Apply manifests to dev cluster using Kustomize
	@echo "Applying to dev namespace..."
	$(KUBECTL) apply -k kubernetes/overlays/dev

kube-apply-prod:  ## Apply manifests to prod cluster using Kustomize
	@echo "Applying to prod namespace..."
	$(KUBECTL) apply -k kubernetes/overlays/prod

kube-delete-dev:  ## Delete dev resources
	@echo "Deleting dev resources..."
	$(KUBECTL) delete -k kubernetes/overlays/dev --ignore-not-found

kube-delete-prod:  ## Delete prod resources
	@echo "Deleting prod resources..."
	$(KUBECTL) delete -k kubernetes/overlays/prod --ignore-not-found

kube-status:  ## Show pod status
	@echo "Pod status in all namespaces:"
	$(KUBECTL) get pods --all-namespaces

kube-logs:  ## Tail logs from demo-app pods
	$(KUBECTL) logs -f -l app.kubernetes.io/name=demo-app --all-namespaces

kube-hpa:  ## Show HPA status
	$(KUBECTL) get hpa --all-namespaces

# ====================
# Helm Commands
# ====================

helm-install-dev:  ## Install demo-app Helm chart in dev
	$(HELM) install demo-app ./helm-charts/demo-app -n dev --values helm-charts/demo-app/values-dev.yaml --create-namespace

helm-install-prod:  ## Install demo-app Helm chart in prod (requires confirmation)
	@echo "WARNING: This will install to PRODUCTION environment."
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(HELM) install demo-app ./helm-charts/demo-app -n prod --values helm-charts/demo-app/values-prod.yaml --create-namespace; \
	fi

helm-upgrade-dev:  ## Upgrade Helm release in dev
	$(HELM) upgrade demo-app ./helm-charts/demo-app -n dev --values helm-charts/demo-app/values-dev.yaml

helm-upgrade-prod:  ## Upgrade Helm release in prod
	@echo "WARNING: This will upgrade PRODUCTION release."
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(HELM) upgrade demo-app ./helm-charts/demo-app -n prod --values helm-charts/demo-app/values-prod.yaml; \
	fi

helm-uninstall-dev:  ## Uninstall from dev
	$(HELM) uninstall demo-app -n dev || true

helm-uninstall-prod:  ## Uninstall from prod
	@echo "WARNING: This will uninstall from PRODUCTION."
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(HELM) uninstall demo-app -n prod || true; \
	fi

# ====================
# Argo CD Commands
# ====================

argocd-login:  ## Login to Argo CD (set ARGOCD_SERVER env var first)
	@echo "Logging into Argo CD at $$ARGOCD_SERVER..."
	$(ARGOCD) login $$ARGOCD_SERVER --username admin --password-insecure or set ARGOCD_PASSWORD

argocd-sync-dev:  ## Sync demo-app-dev application
	$(ARGOCD) app sync demo-app-dev

argocd-sync-prod:  ## Sync demo-app-prod application
	@echo "WARNING: Syncing PRODUCTION application."
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(ARGOCD) app sync demo-app-prod; \
	fi

argocd-status:  ## Show Argo CD application status
	$(ARGOCD) app list

# ====================
# Documentation
# ====================

docs:  ## Generate documentation (if using tools like helm-docs)
	@echo "Generating documentation..."
	@cd helm-charts/demo-app && $(HELM) dependency build
	@echo "Documentation generated. Check helm-docs or Hugo output."

# ====================
# Utilities
# ====================

clean:  ## Clean temporary files
	@echo "Cleaning up..."
	rm -rf infrastructure/.terraform/
	rm -rf infrastructure/terraform.tfstate*
	rm -rf infrastructure/terraform.tfstate.backup
	rm -rf kubernetes/.tmp/
	rm -rf helm-charts/*/charts/
	rm -f kubeconfig-*
	@echo "Clean complete!"

check-prereqs:  ## Check if all prerequisites are installed
	@echo "Checking prerequisites..."
	@command -v $(TERRAFORM) > /dev/null && echo "✓ Terraform" || echo "✗ Terraform not found"
	@command -v $(KUBECTL) > /dev/null && echo "✓ kubectl" || echo "✗ kubectl not found"
	@command -v $(HELM) > /dev/null && echo "✓ Helm" || echo "✗ Helm not found"
	@command -v git > /dev/null && echo "✓ Git" || echo "✗ Git not found"
	@command -v make > /dev/null && echo "✓ Make" || echo "✗ Make not found"

echo-current-dir:  ## Show current working directory
	@echo "Current directory: $(CWD)"
