# Makefile for building and testing Node.js 23 images

# Image names and tags
IMAGE_REPO ?= ghcr.io/the-mines/sbi
IMAGE_NAME ?= node23
IMAGE_TAG ?= latest
DEV_TAG ?= dev

# Full image names
FULL_IMAGE_NAME = $(IMAGE_REPO)/$(IMAGE_NAME)
FULL_DEV_IMAGE_NAME = $(IMAGE_REPO)/$(IMAGE_NAME)-dev

# Default target
.PHONY: all
all: build

# Build both images
.PHONY: build
build: build-base build-dev

# Build base image
.PHONY: build-base
build-base:
	@echo "Building $(FULL_IMAGE_NAME)..."
	docker build -t $(FULL_IMAGE_NAME) -f Dockerfile.node23 .

# Build dev image
.PHONY: build-dev
build-dev:
	@echo "Building $(FULL_DEV_IMAGE_NAME)..."
	docker build -t $(FULL_DEV_IMAGE_NAME) -f Dockerfile.node23-dev .

# Push images to registry
.PHONY: push
push: push-base push-dev

# Push base image
.PHONY: push-base
push-base:
	@echo "Pushing $(FULL_IMAGE_NAME)..."
	docker push $(FULL_IMAGE_NAME)

# Push dev image
.PHONY: push-dev
push-dev:
	@echo "Pushing $(FULL_DEV_IMAGE_NAME)..."
	docker push $(FULL_DEV_IMAGE_NAME)

# Clean up
.PHONY: clean
clean:
	@echo "Removing local images..."
	-docker rmi $(FULL_IMAGE_NAME) $(FULL_DEV_IMAGE_NAME)

# Show help
.PHONY: help
help:
	@echo "Node.js 23 Spellcarver Base Image Build Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  all        - Build both images (default)"
	@echo "  build      - Build both base and dev images"
	@echo "  build-base - Build only base image"
	@echo "  build-dev  - Build only dev image"
	@echo "  push       - Push both images to registry"
	@echo "  push-base  - Push only base image to registry"
	@echo "  push-dev   - Push only dev image to registry"
	@echo "  clean      - Remove local images"
	@echo ""
	@echo "Environment variables:"
	@echo "  IMAGE_REPO - Image repository (default: $(IMAGE_REPO))"
	@echo "  IMAGE_NAME - Image name (default: $(IMAGE_NAME))"
	@echo "  IMAGE_TAG  - Image tag (default: $(IMAGE_TAG))"
	@echo "  DEV_TAG    - Dev image tag (default: $(DEV_TAG))