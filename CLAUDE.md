# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the Spellcarver Base Images (SBI) repository that provides standardized, secure container base images for the Spellcarver application ecosystem. The images are built on Wolfi OS for enhanced security and minimal attack surface.

## Key Commands

### Building Images

**Wolfi Base Image (using apko):**
```bash
cd containers/wolfi-base
apko build wolfi-direct.apko.yaml wolfi-base:latest
# To publish: apko publish wolfi-direct.apko.yaml ghcr.io/the-mines/sbi/wolfi-base:latest
```

**Node.js Images (v22/v23):**
```bash
cd containers/node/node22  # or node23
make build       # Builds both base and dev variants
make test        # Runs all tests
make push        # Pushes to registry (requires auth)
make scan        # Security vulnerability scan
```

**Other Images (Python, PostgreSQL, Cassandra):**
- Built automatically via GitHub Actions on push to main
- Manual builds: `docker build -f containers/{image}/Dockerfile.{image} .`

### Testing

For Node.js images:
```bash
make test-basic     # Basic functionality tests
make test-minimal   # Comprehensive minimal image tests
```

For other images, test scripts are located in `containers/{image}/tests/`

## Architecture & Design Patterns

### Repository Structure
- **containers/** - All container definitions organized by service
  - Each subdirectory contains Dockerfile(s), tests, and specific configurations
  - Node images have Makefiles for local development
  - Wolfi base uses apko configuration instead of Dockerfile

### CI/CD Architecture
1. **Wolfi Base Image Workflow** (`wolfi-base-enhanced.yaml`):
   - Builds Wolfi base using apko tool
   - Runs Monday/Thursday at 8 AM Eastern, Friday at 8 AM UTC
   - Multi-arch support (x86_64, aarch64)
   - Includes cosign signing, SLSA provenance, and Trivy scanning
   - Friday build ensures fresh CVE patches before dependent images build

2. **Container Images Workflow** (`ci.yaml`):
   - Matrix builds for all non-Wolfi images
   - Triggers on push to main, PRs, and weekly (Fridays)
   - Automated security scanning and Slack notifications

### Security Practices
- All images based on minimal Wolfi OS
- Non-root user execution enforced
- Weekly security updates and CVE patching
- Cosign signing for image verification
- SLSA provenance attestations
- Comprehensive Trivy vulnerability scanning

### Image Tagging Strategy
- `latest` - Current stable version
- `YYYYMMDD` - Date-based tags for tracking
- `{short-sha}` - Git commit reference
- `-dev` suffix for development variants

### Key Design Decisions
1. **apko for Wolfi Base**: Direct package management without Docker layers for better security and smaller size
2. **Matrix Builds**: Efficient parallel building across multiple image types
3. **Multi-Stage Dockerfiles**: Separate build and runtime stages to minimize final image size
4. **Automated Weekly Updates**: Friday builds ensure regular security patches

## Development Workflow

1. Create feature branch from main
2. Make changes in appropriate `containers/` subdirectory
3. Test locally (use Makefiles where available)
4. Submit PR - automated CI will run
5. On merge to main, images are automatically built and pushed

## Important Notes

- The Wolfi base image is the foundation for all other images
- When modifying workflow files, ensure compatibility with both scheduled and manual triggers
- Security scanning results don't fail builds but create issues for critical vulnerabilities
- All images are pushed to GitHub Container Registry (ghcr.io/the-mines/sbi/)