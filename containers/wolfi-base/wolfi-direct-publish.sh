#!/bin/bash

set -e

echo "🚀 Publishing wolfi-direct to GHCR..."

# Configuration
REGISTRY="ghcr.io/the-mines/sbi"
IMAGE_NAME="wolfi"
TAG="${1:-latest}"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${TAG}"

# Check if wolfi-direct.apko.yaml exists
if [[ ! -f "wolfi-direct.apko.yaml" ]]; then
    echo "❌ wolfi-direct.apko.yaml not found!"
    echo "Run ./wolfi-direct-build.sh first to generate the apko configuration."
    exit 1
fi

echo "📋 Using configuration: wolfi-direct.apko.yaml"
echo "🏷️  Publishing to: $FULL_IMAGE_NAME"
echo ""

# Check if user is logged in to GHCR
echo "🔐 Checking GHCR authentication..."
if ! docker system info 2>/dev/null | grep -q "Username:"; then
    echo "⚠️  You may need to login to GHCR first:"
    echo "   docker login ghcr.io"
    echo ""
    echo "💡 To create a token:"
    echo "   1. Go to GitHub Settings > Developer settings > Personal access tokens"
    echo "   2. Create token with 'write:packages' scope"
    echo "   3. docker login ghcr.io -u YOUR_USERNAME"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Publish with apko
echo "🔨 Publishing multi-arch image..."
apko publish wolfi-direct.apko.yaml "$FULL_IMAGE_NAME" \
    --arch x86_64,aarch64 \
    --sbom \
    --sbom-formats spdx \
    --vcs

echo ""
echo "✅ Publish complete!"
echo "🎯 Image published to: $FULL_IMAGE_NAME"
echo ""
echo "💡 To pull and test:"
echo "   docker pull $FULL_IMAGE_NAME"
echo "   docker run --rm $FULL_IMAGE_NAME apk list --installed"
echo ""
echo "🔍 To inspect the published image:"
echo "   docker run --rm $FULL_IMAGE_NAME /bin/sh -c 'echo \"Hello from Wolfi Direct!\"'"
echo ""
echo "📋 SBOM files generated:"
echo "   - sbom-index.spdx.json"
echo "   - sbom-x86_64.spdx.json"
echo "   - sbom-aarch64.spdx.json"