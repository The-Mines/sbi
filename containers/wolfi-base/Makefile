# Makefile for building and publishing Wolfi base image

# Image configuration
IMAGE_REPO ?= ghcr.io/the-mines/sbi
IMAGE_NAME ?= wolfi
IMAGE_TAG ?= latest
APKO_CONFIG = wolfi-direct.apko.yaml
OUTPUT_TAR = wolfi-direct-multiarch.tar
ARCHITECTURES = x86_64,aarch64

# Full image name
FULL_IMAGE_NAME = $(IMAGE_REPO)/$(IMAGE_NAME)

# Detect apko installation
APKO := $(shell command -v apko 2> /dev/null)
APKO_CONTAINER = cgr.dev/chainguard/apko:latest

# Default target
.PHONY: all
all: build test

# Check for apko installation
.PHONY: check-apko
check-apko:
ifndef APKO
	@echo "⚠️  apko not found in PATH"
	@echo "💡 Install apko:"
	@echo "   brew install apko (macOS)"
	@echo "   go install chainguard.dev/apko@latest"
	@echo ""
	@echo "🐳 Falling back to containerized apko: $(APKO_CONTAINER)"
	@echo ""
else
	@echo "✅ Using apko: $(APKO)"
	@echo "📋 Version: $$(apko version 2>&1 || echo 'unknown')"
endif

# Build image (local only, creates tar)
.PHONY: build
build: check-apko
	@echo "🔨 Building Wolfi base image..."
	@echo "📋 Config: $(APKO_CONFIG)"
	@echo "🏗️  Architectures: $(ARCHITECTURES)"
ifdef APKO
	apko build $(APKO_CONFIG) $(IMAGE_NAME):$(IMAGE_TAG) $(OUTPUT_TAR) \
		--arch $(ARCHITECTURES) \
		--sbom \
		--sbom-formats spdx
else
	docker run --rm -v "$$(pwd)":/work $(APKO_CONTAINER) \
		build $(APKO_CONFIG) $(IMAGE_NAME):$(IMAGE_TAG) $(OUTPUT_TAR) \
		--arch $(ARCHITECTURES) \
		--sbom \
		--sbom-formats spdx
endif
	@echo "✅ Build complete!"
	@echo "📦 Output: $(OUTPUT_TAR)"
	@echo ""
	@echo "💡 To load into Docker:"
	@echo "   docker load < $(OUTPUT_TAR)"

# Load the built image into Docker
.PHONY: load
load: build
	@echo "📥 Loading image into Docker..."
	docker load < $(OUTPUT_TAR)
	@echo "✅ Image loaded!"
	@echo "🔍 Listing loaded images:"
	@docker images | grep $(IMAGE_NAME) || echo "No images found"

# Publish image directly to registry (build + push in one step)
.PHONY: publish
publish: check-apko check-auth
	@echo "🚀 Publishing Wolfi base image to registry..."
	@echo "🎯 Target: $(FULL_IMAGE_NAME):$(IMAGE_TAG)"
ifdef APKO
	apko publish $(APKO_CONFIG) $(FULL_IMAGE_NAME):$(IMAGE_TAG) \
		--arch $(ARCHITECTURES) \
		--sbom \
		--sbom-formats spdx \
		--vcs
else
	docker run --rm \
		-v "$$(pwd)":/work \
		-v $$HOME/.docker:/root/.docker:ro \
		$(APKO_CONTAINER) \
		publish $(APKO_CONFIG) $(FULL_IMAGE_NAME):$(IMAGE_TAG) \
		--arch $(ARCHITECTURES) \
		--sbom \
		--sbom-formats spdx \
		--vcs
endif
	@echo "✅ Publish complete!"
	@echo "📋 SBOM files generated:"
	@ls -lh sbom-*.spdx.json 2>/dev/null || echo "No SBOM files found"

# Check registry authentication
.PHONY: check-auth
check-auth:
	@echo "🔐 Checking container registry authentication..."
	@if ! docker system info 2>/dev/null | grep -q "Username:"; then \
		echo "⚠️  Not logged in to container registry"; \
		echo "💡 Login with: docker login $(IMAGE_REPO)"; \
		echo ""; \
		read -p "Continue anyway? (y/N): " -n 1 -r; \
		echo; \
		if [ "$$REPLY" != "y" ] && [ "$$REPLY" != "Y" ]; then \
			echo "Aborted."; \
			exit 1; \
		fi; \
	else \
		echo "✅ Authenticated"; \
	fi

# Test the image
.PHONY: test
test: load
	@echo "🧪 Testing Wolfi base image..."
	@echo "1️⃣  Checking image exists..."
	@docker images $(IMAGE_NAME):$(IMAGE_TAG)-amd64 >/dev/null 2>&1 || \
		(echo "❌ Image not found. Run 'make load' first." && exit 1)
	@echo "✅ Image exists"
	@echo ""
	@echo "2️⃣  Testing basic functionality..."
	@docker run --rm $(IMAGE_NAME):$(IMAGE_TAG)-amd64 /bin/sh -c 'echo "Hello from Wolfi!"' || \
		(echo "❌ Failed to run container" && exit 1)
	@echo "✅ Container runs successfully"
	@echo ""
	@echo "3️⃣  Checking installed packages..."
	@docker run --rm $(IMAGE_NAME):$(IMAGE_TAG)-amd64 apk list --installed || \
		(echo "❌ Failed to list packages" && exit 1)
	@echo "✅ Package listing works"
	@echo ""
	@echo "4️⃣  Verifying non-root user..."
	@docker run --rm $(IMAGE_NAME):$(IMAGE_TAG)-amd64 id | grep -q "uid=65532(nonroot)" || \
		(echo "❌ Not running as nonroot user" && exit 1)
	@echo "✅ Running as nonroot user (uid=65532)"
	@echo ""
	@echo "✅ All tests passed!"

# Scan image for vulnerabilities
.PHONY: scan
scan: load
	@echo "🔍 Scanning Wolfi base image for vulnerabilities..."
	@if command -v trivy >/dev/null 2>&1; then \
		trivy image --severity HIGH,CRITICAL $(IMAGE_NAME):$(IMAGE_TAG)-amd64; \
	else \
		echo "⚠️  Trivy not found. Install with:"; \
		echo "   brew install trivy (macOS)"; \
		echo "   Or use: docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image $(IMAGE_NAME):$(IMAGE_TAG)-amd64"; \
	fi

# Inspect SBOM files
.PHONY: sbom
sbom:
	@echo "📋 SBOM files in current directory:"
	@ls -lh sbom-*.spdx.json 2>/dev/null || echo "No SBOM files found. Run 'make build' first."
	@echo ""
	@echo "💡 To view SBOM contents:"
	@echo "   jq . sbom-index.spdx.json | less"
	@echo "   jq '.packages[].name' sbom-x86_64.spdx.json"

# Check for package updates
.PHONY: check-updates
check-updates:
	@echo "🔄 Checking for Wolfi package updates..."
	@echo "📦 Current packages in $(APKO_CONFIG):"
	@grep -A 10 "packages:" $(APKO_CONFIG) || echo "Could not read config"
	@echo ""
	@echo "💡 To see latest available packages:"
	@echo "   curl -s https://packages.wolfi.dev/os/x86_64/APKINDEX.tar.gz | tar -xzO APKINDEX | grep -A 5 'P:wolfi-base'"

# Clean up generated files
.PHONY: clean
clean:
	@echo "🧹 Cleaning up generated files..."
	-rm -f $(OUTPUT_TAR)
	-rm -f sbom-*.spdx.json
	-docker rmi $(IMAGE_NAME):$(IMAGE_TAG)-amd64 2>/dev/null || true
	-docker rmi $(IMAGE_NAME):$(IMAGE_TAG)-arm64 2>/dev/null || true
	@echo "✅ Cleanup complete!"

# Show image info
.PHONY: info
info:
	@echo "📊 Wolfi Base Image Information"
	@echo "================================"
	@echo "Registry:      $(IMAGE_REPO)"
	@echo "Image Name:    $(IMAGE_NAME)"
	@echo "Full Name:     $(FULL_IMAGE_NAME)"
	@echo "Tag:           $(IMAGE_TAG)"
	@echo "Config File:   $(APKO_CONFIG)"
	@echo "Architectures: $(ARCHITECTURES)"
	@echo "Output File:   $(OUTPUT_TAR)"
	@echo ""
	@if [ -f $(OUTPUT_TAR) ]; then \
		echo "📦 Local build exists: $(OUTPUT_TAR)"; \
		ls -lh $(OUTPUT_TAR); \
	else \
		echo "📦 No local build found"; \
	fi
	@echo ""
	@if [ -f sbom-index.spdx.json ]; then \
		echo "📋 SBOM files exist:"; \
		ls -lh sbom-*.spdx.json; \
	else \
		echo "📋 No SBOM files found"; \
	fi

# Show help
.PHONY: help
help:
	@echo "Wolfi Base Image Build Makefile"
	@echo "================================"
	@echo ""
	@echo "Available targets:"
	@echo "  all            - Build and test image (default)"
	@echo "  build          - Build multi-arch image tar file"
	@echo "  load           - Load built image into Docker"
	@echo "  publish        - Build and publish directly to registry"
	@echo "  test           - Run tests on loaded image"
	@echo "  scan           - Scan image for vulnerabilities with Trivy"
	@echo "  sbom           - Show SBOM file information"
	@echo "  check-updates  - Check for Wolfi package updates"
	@echo "  check-apko     - Verify apko installation"
	@echo "  check-auth     - Check registry authentication"
	@echo "  info           - Show image and build information"
	@echo "  clean          - Remove generated files and images"
	@echo "  help           - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  IMAGE_REPO     - Image repository (default: $(IMAGE_REPO))"
	@echo "  IMAGE_NAME     - Image name (default: $(IMAGE_NAME))"
	@echo "  IMAGE_TAG      - Image tag (default: $(IMAGE_TAG))"
	@echo "  APKO_CONFIG    - apko config file (default: $(APKO_CONFIG))"
	@echo "  ARCHITECTURES  - Target architectures (default: $(ARCHITECTURES))"
	@echo ""
	@echo "Examples:"
	@echo "  make build                    # Build locally"
	@echo "  make test                     # Build and test"
	@echo "  make publish                  # Publish to registry"
	@echo "  make IMAGE_TAG=v1.0.0 publish # Publish with custom tag"
	@echo "  make scan                     # Security scan"
