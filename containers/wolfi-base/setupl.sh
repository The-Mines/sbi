#!/bin/bash
set -eo pipefail

# Clean any previous build artifacts
rm -rf rootfs wolfi-base.tar || true

# Make temporary directory for keys
mkdir -p keys
echo "Downloading Wolfi signing key..."
curl -sSL -o keys/wolfi-signing.rsa.pub https://packages.wolfi.dev/os/wolfi-signing.rsa.pub

# Ensure we have the key locally
if [ ! -f keys/wolfi-signing.rsa.pub ]; then
  echo "Error: Failed to download Wolfi signing key"
  exit 1
fi

echo "Building with apko..."
apko build apko.yaml wolfi-base:latest wolfi-base.tar

echo "Building Docker image..."
docker build -t wolfi-base .

echo "Extracting rootfs..."
mkdir -p rootfs && tar -xf wolfi-base.tar -C rootfs

echo "Build completed successfully!"