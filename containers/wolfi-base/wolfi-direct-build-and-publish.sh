#!/bin/bash

set -e

echo "🚀 Building and Publishing wolfi-direct to GHCR..."

# Configuration
REGISTRY="ghcr.io/the-mines/sbi"
IMAGE_NAME="wolfi"
TAG="${1:-latest}"
BUILD_ONLY="${2:-false}"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "🏷️  Target: $FULL_IMAGE_NAME"
echo "🔧 Build only: $BUILD_ONLY"
echo ""

# Step 1: Build the image
echo "📦 Step 1: Building wolfi-direct image..."
./wolfi-direct-build.sh

if [[ "$BUILD_ONLY" == "true" ]]; then
    echo ""
    echo "✅ Build complete (build-only mode)!"
    echo "📦 Generated: wolfi-direct-multiarch.tar"
    echo ""
    echo "💡 To publish later:"
    echo "   ./wolfi-direct-publish.sh $TAG"
    exit 0
fi

echo ""
echo "📤 Step 2: Publishing to registry..."

# Check if user is logged in to GHCR
echo "🔐 Checking GHCR authentication..."
if ! docker system info 2>/dev/null | grep -q "Username:"; then
    echo "⚠️  You need to login to GHCR first:"
    echo "   docker login ghcr.io"
    echo ""
    echo "💡 To create a token:"
    echo "   1. Go to GitHub Settings > Developer settings > Personal access tokens"
    echo "   2. Create token with 'write:packages' scope"
    echo "   3. docker login ghcr.io -u YOUR_USERNAME"
    echo ""
    echo "❌ Cannot publish without authentication."
    exit 1
fi

# Publish with apko
echo "🔨 Publishing multi-arch image..."
apko publish wolfi-direct.apko.yaml "$FULL_IMAGE_NAME" \
    --arch x86_64,aarch64 \
    --sbom \
    --sbom-formats spdx \
    --vcs

echo ""
echo "🎉 Build and Publish complete!"
echo "🎯 Image published to: $FULL_IMAGE_NAME"
echo ""
echo "💡 Quick test commands:"
echo "   docker pull $FULL_IMAGE_NAME"
echo "   docker run --rm $FULL_IMAGE_NAME apk list --installed"
echo "   docker run --rm $FULL_IMAGE_NAME /bin/sh -c 'echo \"Hello from Wolfi Direct!\"'"
echo ""
echo "📋 Generated files:"
echo "   - wolfi-direct-multiarch.tar (local)"
echo "   - sbom-*.spdx.json (SBOM files)"
echo "   - $FULL_IMAGE_NAME (published)"