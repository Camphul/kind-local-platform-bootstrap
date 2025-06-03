.PHONY: cluster-create cluster-destroy helmfile-apply help
.DEFAULT_GOAL := help

help:
	@echo "Available targets:"
	@echo "  cluster-create    - Create a new Kind cluster using kind-config.yaml"
	@echo "  cluster-destroy   - Destroy the Kind cluster"
	@echo "  helmfile-apply    - Apply helmfile to the Kind cluster"
	@echo "  up    - Create cluster and apply helmfile"
	@echo "  down  - Destroy and cleanup"


KIND_CLUSTER_NAME ?= local-kind
KIND_CONTEXT_NAME ?= kind-$(KIND_CLUSTER_NAME)

KUBECONFIG_PATH_FILE := .kubeconfig_path

# Create the kind cluster using the config file
cluster-create:
	@echo "Creating Kind cluster $(KIND_CLUSTER_NAME)..."
	kind create cluster --name $(KIND_CLUSTER_NAME) --config kind-config.yaml
	@TMPDIR=$${TMPDIR:-/tmp}; \
	KUBECONFIG_DIR=$$(mktemp -d "$$TMPDIR/kind.XXXXXX"); \
	KUBECONFIG_FILE="$$KUBECONFIG_DIR/kubeconfig"; \
	kubectl config view --minify --flatten --context $(KIND_CONTEXT_NAME) > "$$KUBECONFIG_FILE"; \
	echo "$$KUBECONFIG_FILE" > $(KUBECONFIG_PATH_FILE); \
	echo "Extracted kubeconfig context to $$KUBECONFIG_FILE"; \
	kubectl --kubeconfig "$$KUBECONFIG_FILE" cluster-info
	@echo "Cluster created successfully!"

# Destroy the kind cluster
cluster-destroy:
	@echo "Destroying Kind cluster $(KIND_CLUSTER_NAME)..."
	kind delete cluster --name $(KIND_CLUSTER_NAME)
	@rm -f $(KUBECONFIG_PATH_FILE)
	@echo "Cluster destroyed successfully!"

# Apply helmfile to the kind cluster
helmfile-apply:
	@echo "Applying helmfile to kind-$(KIND_CLUSTER_NAME) cluster..."
	@KUBECONFIG_FILE=$$(cat $(KUBECONFIG_PATH_FILE)); \
	helmfile --kubeconfig "$$KUBECONFIG_FILE" init; \
	helmfile --kubeconfig "$$KUBECONFIG_FILE" apply
	@echo "Helmfile applied successfully!"

up:
	@$(MAKE) cluster-create
	@$(MAKE) helmfile-apply

down:
	@$(MAKE) cluster-destroy