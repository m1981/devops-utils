.PHONY: help setup build-all test-all encrypt decrypt

# Default target when just running 'make'
.DEFAULT_GOAL := help

# Colors for help message
BLUE := \033[36m
NC := \033[0m # No Color

# Help target
help: ## Display this help message
	@echo "Usage: make ${BLUE}<target>${NC}"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${BLUE}%-15s${NC} %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Initial steps:"
	@echo "  make build-all"
	@echo "  make generate-keys"

build-all: ## Build all utility containers
	./scripts/build-and-test.sh

security-check: ## Run security checks
	./scripts/security/run-checks.sh

generate-keys: ## Generate new Age keys
	./scripts/generate-keys.sh

encrypt: ## Encrypt secrets file (Usage: make encrypt FILE=secrets/dev.yaml)
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE parameter is required"; \
		echo "Usage: make encrypt FILE=secrets/dev.yaml"; \
		exit 1; \
	fi
	./scripts/encrypt-secrets.sh $(FILE)

decrypt: ## Decrypt secrets file (Usage: make decrypt FILE=secrets/dev.enc.yaml)
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE parameter is required"; \
		echo "Usage: make decrypt FILE=secrets/dev.enc.yaml"; \
		exit 1; \
	fi
	./scripts/decrypt-secrets.sh $(FILE)
