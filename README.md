# Spellcarver Base Images (SBI)

This repository is maintained by Merlin Mines to provide standardized, secure container base images for the Spellcarver application ecosystem. All images are built on Wolfi OS for enhanced security and minimal attack surface.

## Overview

The Spellcarver Base Images repository contains a collection of carefully curated Docker container images that serve as the foundation for various components of the Spellcarver application. These images are designed to ensure consistent development and deployment environments across the entire platform.

## Security and Updates

Our images are built on the secure Wolfi OS base, a minimalist, security-focused operating system designed specifically for containers. To maintain the highest security standards:

- **Wolfi Base:** Automated builds Monday/Thursday at 8 AM Eastern
- **Other Images:** Automated builds every Friday at 9 AM UTC
- **Push to Main:** All images rebuild automatically on commits to main branch
- Regular CVE (Common Vulnerabilities and Exposures) scans and patches using Trivy
- Cosign signing for image verification
- SLSA provenance attestations for supply chain security
- SBOM (Software Bill of Materials) generation for all images

## Supported Images

All images are published to GitHub Container Registry at `ghcr.io/the-mines/sbi/`.

### Wolfi Base
- **Repository:** `ghcr.io/the-mines/sbi/wolfi`
- **Architecture:** Multi-arch (linux/amd64, linux/arm64)
- **Build Tool:** apko (declarative image builds)
- **Base Packages:** wolfi-base, ca-certificates-bundle
- **User:** nonroot (UID/GID: 65532)

### Node.js Images
- **node22** - Node.js 22 LTS minimal runtime
- **node22-dev** - Node.js 22 LTS with development tools
- **node23** - Node.js 23 minimal runtime
- **node23-dev** - Node.js 23 with development tools
- **Features:** dumb-init for proper signal handling, non-root execution, no npm/busybox in minimal variants

### Database Images
- **postgres** - PostgreSQL 17 with pgaudit and postgresql-oci-entrypoint
- **cassandra** - Apache Cassandra 5.0.1 with Medusa backup integration

### Language Runtime Images
- **python311** - Python 3.11 with virtual environment support

### Compatibility Images
- **git-init-compat** - Legacy Tekton git-clone task compatibility layer

## Build Automation

### CI/CD Workflows

**Base Image Workflow** (`.github/workflows/base-image-build-and-push.yaml`):
- Builds Wolfi base image using apko tool
- Multi-architecture support (x86_64, aarch64)
- Automated security scanning with Trivy
- Cosign keyless signing
- SLSA provenance generation
- Runs Monday/Thursday at 8 AM Eastern and on manual dispatch

**Container Images Workflow** (`.github/workflows/ci.yaml`):
- Matrix-based builds for all non-Wolfi images
- Automated on push to main, PRs, and weekly on Fridays
- Comprehensive security scanning
- Automated Slack notifications with build status
- Creates GitHub issues on build failures

### Image Tagging Strategy
- `latest` - Current stable version
- `YYYYMMDD` - Date-based tags from scheduled builds
- `{env}-{short-sha}` - Environment and commit reference (e.g., `dev-4652ab4`)
- `-dev` suffix - Development variants with additional tooling

## Local Development

### Building Wolfi Base Image
```bash
cd containers/wolfi-base
apko build wolfi-direct.apko.yaml wolfi-base:latest wolfi-direct-multiarch.tar
# To publish: apko publish wolfi-direct.apko.yaml ghcr.io/the-mines/sbi/wolfi:latest
```

### Building Node.js Images
```bash
cd containers/node/node22  # or node23
make build       # Builds both base and dev variants
make test        # Runs all tests
make push        # Pushes to registry (requires auth)
make scan        # Security vulnerability scan
```

### Building Other Images
```bash
# Python 3.11
docker build -f containers/python311/Dockerfile -t ghcr.io/the-mines/sbi/python311:latest .

# PostgreSQL 17
docker build -f containers/postgres/Dockerfile -t ghcr.io/the-mines/sbi/postgres:latest .

# Cassandra 5.0.1
docker build -f containers/cassandra/Dockerfile -t ghcr.io/the-mines/sbi/cassandra:latest .

# Git-init compatibility
cd containers/wolfi-base/git-init-compat
make build
```

## Open Source

All container images and configurations in this repository are free and open-source. We believe in the power of community-driven development and welcome contributions from developers worldwide.

## Contributing

We welcome contributions from the community! If you'd like to contribute, please:
1. Fork the repository
2. Create a feature branch from `main`
3. Test your changes locally (use Makefiles where available)
4. Submit a Pull Request - automated CI will validate your changes
5. On merge to main, images are automatically built and pushed

## Security Practices

- **Non-root Execution:** All images run as non-root users by default
- **Minimal Attack Surface:** Based on Wolfi OS with only essential packages
- **Regular Updates:** Automated weekly builds ensure latest security patches
- **Vulnerability Scanning:** Trivy scans on every build
- **Supply Chain Security:** Cosign signatures and SLSA provenance
- **SBOM Generation:** Complete software bill of materials for transparency

## License

This project is open-source and freely available for use by anyone.

## Custom Images & Migration Services

Need custom container images or help migrating your infrastructure to Wolfi OS? Merlin Mines offers professional services to:
- Build custom, secure container images for your specific needs
- Assist with migration of existing applications to Wolfi OS
- Provide consultation on container security and best practices

Reach out to Merlin Mines for enterprise support and custom solutions by emailing `info@spellcarver.com`.
## Contact

For questions or support, please open an issue in this repository.

---
Maintained by Merlin Mines
