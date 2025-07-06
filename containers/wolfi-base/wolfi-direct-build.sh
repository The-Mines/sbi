#!/bin/bash

set -e

echo "🐺 Building wolfi-base using direct Wolfi repositories..."

# Create a minimal apko config that uses only Wolfi repos
cat > wolfi-direct.apko.yaml <<EOF
contents:
  repositories:
    - https://packages.wolfi.dev/os
  keyring:
    - https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
  packages:
    - wolfi-base
    - ca-certificates-bundle

accounts:
  groups:
    - groupname: nonroot
      gid: 65532
  users:
    - username: nonroot
      uid: 65532
      gid: 65532
  run-as: 65532

cmd: /bin/sh -l

environment:
  PATH: /usr/sbin:/sbin:/usr/bin:/bin
EOF

echo "📋 Generated wolfi-direct.apko.yaml"
echo "📄 Contents:"
cat wolfi-direct.apko.yaml

echo ""
echo "🔨 Building with apko..."

# Build for both architectures
apko build wolfi-direct.apko.yaml wolfi-direct:latest wolfi-direct-multiarch.tar \
  --arch x86_64,aarch64

echo ""
echo "✅ Build complete!"
echo "📦 Generated: wolfi-direct-multiarch.tar"
echo ""
echo "💡 To load into Docker:"
echo "   docker load < wolfi-direct-multiarch.tar"
echo ""
echo "🔍 To inspect packages:"
echo "   docker run --rm wolfi-direct:latest-amd64 apk list --installed"