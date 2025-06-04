ifneq (,$(wildcard ./.env))
    include .env
    export
endif
# Configuration
CLUSTER_NAME := local-kind
KUBECONFIG_PATH_FILE := .kubeconfig_path

# ANSI color codes
YELLOW := \033[1;33m
RED := \033[1;31m
GREEN := \033[1;32m
NC := \033[0m # No Color
INFO := @printf "$(GREEN)➜ $(NC)"
WARN := @printf "$(YELLOW)⚠ $(NC)"
ERROR := @printf "$(RED)✗ $(NC)"

# Function to get or create kubeconfig path
define get_kubeconfig_path
$(shell if [ -f $(KUBECONFIG_PATH_FILE) ]; then cat $(KUBECONFIG_PATH_FILE); else \
	TEMP_KUBECONFIG=$$(mktemp); \
	echo "$$TEMP_KUBECONFIG" > $(KUBECONFIG_PATH_FILE); \
	echo "$$TEMP_KUBECONFIG"; \
fi)
endef

.PHONY: help
help: ## Display this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: check-env
check-env: ## Verify required environment variables
	@if [ ! -f .env ]; then \
		$(WARN) ".env file not found. Copying from .env.example..."; \
		cp .env.example .env; \
		echo "Please review and adjust the .env file as needed."; \
	fi

.PHONY: check-deps
check-deps: ## Check if required dependencies are installed
	@$(INFO) "Checking dependencies..."
	@command -v kind >/dev/null 2>&1 || { $(ERROR) "kind is required but not installed. Aborting."; exit 1; }
	@command -v helmfile >/dev/null 2>&1 || { $(ERROR) "helmfile is required but not installed. Aborting."; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { $(ERROR) "kubectl is required but not installed. Aborting."; exit 1; }
	@command -v docker >/dev/null 2>&1 || { $(ERROR) "docker is required but not installed. Aborting."; exit 1; }

.PHONY: kubeconfig
kubeconfig: ## Generate kubeconfig for the Kind cluster
	@$(INFO) "Generating kubeconfig file..."
	@kind get kubeconfig --name $(CLUSTER_NAME) > $(call get_kubeconfig_path)


.PHONY: cluster-create
cluster-create: check-deps check-env ## Create a new Kind cluster using kind-config.yaml
	@$(INFO) "Creating Kind cluster..."
	@kind create cluster --config kind-config.yaml --name $(CLUSTER_NAME)
	@$(MAKE) kubeconfig


.PHONY: cluster-destroy
cluster-destroy: ## Destroy the Kind cluster (requires confirmation)
	@$(WARN) "This will destroy the Kind cluster. Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@$(INFO) "Destroying Kind cluster..."
	@kind delete cluster --name $(CLUSTER_NAME)
	@if [ -f $(KUBECONFIG_PATH_FILE) ]; then \
		rm -f $$(cat $(KUBECONFIG_PATH_FILE)) $(KUBECONFIG_PATH_FILE); \
	fi


.PHONY: helmfile-apply
helmfile-apply: check-deps check-env ## Apply helmfile to the Kind cluster
	@$(INFO) "Applying Helmfile configuration..."
	@helmfile --kubeconfig $(call get_kubeconfig_path) apply --environment default

.PHONY: helmfile-sync
helmfile-sync: check-deps check-env ## Apply helmfile to the Kind cluster
	@$(INFO) "Syncing Helmfile configuration..."
	@helmfile --kubeconfig $(call get_kubeconfig_path) sync --environment default


.PHONY: helmfile-destroy
helmfile-destroy: ## Destroy Helmfile resources (requires confirmation)
	@$(WARN) "This will destroy all Helmfile resources. Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@$(INFO) "Destroying Helmfile resources..."
	@helmfile --kubeconfig $(call get_kubeconfig_path) destroy --environment default

.PHONY: up
up: cluster-create helmfile-apply ## Create cluster and apply helmfile configuration

.PHONY: down
down: ## Destroy and cleanup everything (requires confirmation)
	@$(WARN) "This will destroy everything. Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@$(INFO) "Starting cleanup..."
	@-$(MAKE) helmfile-destroy
	@-$(MAKE) cluster-destroy

.PHONY: status
status: ## Show cluster and deployment status
	@$(INFO) "Cluster Status:"
	@kind get clusters
	@$(INFO) "Node Status:"
	@KUBECONFIG=$(KUBECONFIG) kubectl get nodes
	@$(INFO) "Deployment Status:"
	@KUBECONFIG=$(KUBECONFIG) kubectl get pods --all-namespaces

.DEFAULT_GOAL := help
