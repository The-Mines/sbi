# Wolfi Base Image

The Wolfi base image is the foundation for all Spellcarver Base Images (SBI). Built with [apko](https://github.com/chainguard-dev/apko) on [Wolfi OS](https://github.com/wolfi-dev/os), it provides a minimal, secure, and reproducible base for containerized applications.

## Features

- **Minimal Attack Surface**: Contains only essential packages (wolfi-base, ca-certificates-bundle)
- **Non-Root by Default**: Runs as user `nonroot` (UID/GID: 65532)
- **Multi-Architecture**: Supports both amd64 (x86_64) and arm64 (aarch64)
- **Reproducible Builds**: Declarative apko configuration ensures consistent builds
- **SBOM Generation**: Automatic Software Bill of Materials in SPDX format
- **Security Signed**: Images signed with cosign and SLSA provenance attestations
- **Automated Updates**: Weekly checks for Wolfi package updates

## Quick Start

### Prerequisites

- **apko** (optional for local builds): `brew install apko` or use Docker fallback
- **Docker**: For image loading and testing
- **make**: For using the Makefile commands

### Local Development

```bash
# Build the image locally
make build

# Load into Docker and run tests
make test

# Publish to registry (requires authentication)
make publish

# Scan for vulnerabilities
make scan

# Get help
make help
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make all` | Build and test the image (default) |
| `make build` | Build multi-arch image as tar file |
| `make load` | Load built image into Docker |
| `make publish` | Build and publish directly to registry |
| `make test` | Run comprehensive test suite |
| `make scan` | Security scan with Trivy |
| `make sbom` | Show SBOM information |
| `make check-updates` | Check for Wolfi package updates |
| `make info` | Display image and build information |
| `make clean` | Remove generated files and images |

### Environment Variables

Customize builds with environment variables:

```bash
# Use custom registry
IMAGE_REPO=ghcr.io/myorg/images make build

# Build with custom tag
IMAGE_TAG=v1.0.0 make publish

# Use different apko config
APKO_CONFIG=custom.apko.yaml make build
```

## Configuration

### apko Configuration File

The image is built from `wolfi-direct.apko.yaml`:

```yaml
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
```

### Package Management

To add packages, update the `packages` section in `wolfi-direct.apko.yaml`:

```yaml
packages:
  - wolfi-base
  - ca-certificates-bundle
  - curl  # Add new package
  - git   # Add another package
```

Browse available packages at [packages.wolfi.dev/os](https://packages.wolfi.dev/os).

## Automated Workflows

### Enhanced Build & Publish Workflow

**File**: `.github/workflows/wolfi-base-enhanced.yaml`

**Schedule**: Monday and Thursday at 8:00 AM Eastern (13:00 UTC)

**Triggers**:
- Scheduled builds (Mon/Thu)
- Push to main (when wolfi-base files change)
- Pull requests (build only, no push)
- Manual workflow dispatch

**Features**:
- Native apko installation (faster builds)
- Single-step build and publish with `apko publish`
- Automated multi-arch manifest creation
- Cosign keyless signing
- SLSA provenance attestation
- Trivy security scanning (SARIF + table output)
- Upload to GitHub Security tab
- Comprehensive build summaries
- Slack notifications
- Automatic issue creation on failures

**Tags Created**:
- `latest` - Always updated
- `YYYYMMDD` - Date-based for scheduled builds
- `{short-sha}` - Git commit reference
- Custom tags via workflow dispatch

### Package Update Detection Workflow

**File**: `.github/workflows/wolfi-package-updates.yaml`

**Schedule**: Every Monday at 9:00 AM UTC

**Purpose**: Automatically checks the Wolfi package repository for updates and package availability.

**Actions**:
- Downloads and parses Wolfi APKINDEX
- Verifies all configured packages are available
- Tracks package statistics
- Creates GitHub issues for attention items
- Generates detailed summary reports
- Slack notifications

**Manual Trigger**:
```bash
# Via GitHub CLI
gh workflow run wolfi-package-updates.yaml

# Via GitHub UI
Actions -> Check Wolfi Package Updates -> Run workflow
```

## Testing

### Automated Test Suite

Run the comprehensive test suite:

```bash
# Test the loaded image
make test

# Or run the test script directly
IMAGE_NAME=wolfi:latest-amd64 ./test-wolfi-base.sh
```

### Test Categories

1. **Basic Tests**
   - Image existence
   - Container startup
   - Shell availability

2. **Security Tests**
   - Non-root user verification
   - Filesystem permissions
   - No setuid binaries

3. **Package Management Tests**
   - apk availability
   - Package listing
   - Minimal footprint (<50 packages)

4. **System Tests**
   - CA certificates
   - Environment variables
   - Basic Unix commands
   - Network stack

### Manual Testing

```bash
# Load the image
docker load < wolfi-direct-multiarch.tar

# Run interactively
docker run --rm -it wolfi:latest-amd64 /bin/sh

# Check installed packages
docker run --rm wolfi:latest-amd64 apk list --installed

# Verify user
docker run --rm wolfi:latest-amd64 id

# Test filesystem
docker run --rm wolfi:latest-amd64 ls -la /
```

## Security

### Signing and Verification

All published images are signed with cosign:

```bash
# Verify signature
cosign verify \
  --certificate-identity-regexp "https://github.com/the-mines/sbi/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/the-mines/sbi/wolfi:latest

# Verify attestations
cosign verify-attestation \
  --certificate-identity-regexp "https://github.com/the-mines/sbi/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/the-mines/sbi/wolfi:latest
```

### SBOM (Software Bill of Materials)

SBOMs are automatically generated in SPDX format:

```bash
# View SBOM files after build
ls -lh sbom-*.spdx.json

# Inspect SBOM contents
jq . sbom-index.spdx.json | less

# List packages from SBOM
jq '.packages[].name' sbom-x86_64.spdx.json
```

### Vulnerability Scanning

```bash
# Scan with Trivy
make scan

# Or scan directly
trivy image --severity HIGH,CRITICAL wolfi:latest-amd64

# Check GitHub Security tab for SARIF uploads
# https://github.com/the-mines/sbi/security/code-scanning
```

## Troubleshooting

### apko Not Found

If apko is not installed, the Makefile automatically falls back to the containerized version:

```bash
# The Makefile will use this automatically:
docker run --rm -v "$(pwd)":/work cgr.dev/chainguard/apko:latest build ...
```

### Registry Authentication

Before publishing, ensure you're logged in:

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Or use GitHub CLI
gh auth token | docker login ghcr.io -u USERNAME --password-stdin
```

### Build Failures

1. Check apko configuration syntax:
   ```bash
   yq eval wolfi-direct.apko.yaml
   ```

2. Verify package availability:
   ```bash
   make check-updates
   ```

3. Review workflow logs:
   ```bash
   gh run list --workflow=wolfi-base-enhanced.yaml
   gh run view <run-id>
   ```

### Image Not Loading

If the image doesn't load correctly:

```bash
# Rebuild
make clean
make build

# Verify tar file
file wolfi-direct-multiarch.tar

# Try loading with verbose output
docker load -i wolfi-direct-multiarch.tar
```

## Package Retention Policy

**Important**: Wolfi implements a package retention policy:

- Non-latest versions older than 12 months will be removed (reducing to 3 months)
- Removal happens on the second Wednesday of each month
- Always use the latest packages when possible
- Monitor the package update workflow for notifications

## Resources

- [Wolfi OS Documentation](https://edu.chainguard.dev/open-source/wolfi/overview/)
- [apko Documentation](https://github.com/chainguard-dev/apko)
- [Wolfi Package Repository](https://packages.wolfi.dev/os)
- [Wolfi Security Advisories](https://github.com/wolfi-dev/advisories)
- [Chainguard Academy](https://edu.chainguard.dev/)

## Contributing

When modifying the Wolfi base configuration:

1. Update `wolfi-direct.apko.yaml` with your changes
2. Test locally: `make build && make test`
3. Create a PR - the workflow will build (but not push)
4. After merge, the workflow automatically publishes the new image

## Support

- **Issues**: [GitHub Issues](https://github.com/the-mines/sbi/issues)
- **Discussions**: [GitHub Discussions](https://github.com/the-mines/sbi/discussions)
- **Security**: Report vulnerabilities via GitHub Security Advisories

## License

This project is open-source and freely available. See LICENSE for details.

---

**Maintained by Merlin Mines**

*Building secure, minimal, and reproducible container images for the Spellcarver ecosystem.*
