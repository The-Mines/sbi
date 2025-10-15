# Migration Guide: Old Workflow → Enhanced Workflow

This guide explains how to transition from the manual shell scripts to the new automated workflow system.

## Overview of Changes

### Before (Manual Process)
- Run `./wolfi-direct-build.sh` manually
- Run `./wolfi-direct-publish.sh` manually
- Manual Docker commands for testing
- No automated package update checking
- Complex workflow with Docker-wrapped apko

### After (Automated Process)
- Simple `make` commands for local development
- Automated GitHub Actions workflows
- Comprehensive testing suite
- Automated package update detection
- Streamlined workflow with native apko

## For Local Development

### Old Way
```bash
# Build
./wolfi-direct-build.sh

# Publish
./wolfi-direct-publish.sh latest

# Combined
./wolfi-direct-build-and-publish.sh latest
```

### New Way
```bash
# Build
make build

# Publish
make publish

# Build and test
make all

# Additional features
make scan        # Security scan
make test        # Run tests
make info        # Show info
make check-updates  # Check for package updates
```

### Benefits
- ✅ Consistent interface (same as node22/node23)
- ✅ Auto-detects apko installation
- ✅ Better error messages
- ✅ Built-in testing
- ✅ Environment variable support

## For CI/CD

### Old Workflow (`base-image-build-and-push.yaml`)

**Issues**:
- Docker-wrapped apko (slower, more complex)
- Manual per-arch builds
- Complex manifest creation
- Limited package information tracking

### New Workflow (`wolfi-base-enhanced.yaml`)

**Improvements**:
- Native apko installation (faster)
- Single-step `apko publish` command
- Automatic multi-arch handling
- Package tracking in provenance
- Better error handling
- More detailed summaries
- SARIF output for GitHub Security

### Migration Steps

1. **Review the new workflow**:
   ```bash
   cat .github/workflows/wolfi-base-enhanced.yaml
   ```

2. **Test locally first**:
   ```bash
   cd containers/wolfi-base
   make build
   make test
   ```

3. **Disable old workflow** (recommended approach):
   ```bash
   # Rename to disable
   mv .github/workflows/base-image-build-and-push.yaml \
      .github/workflows/base-image-build-and-push.yaml.disabled
   ```

4. **Enable new workflow**:
   - The new workflow is ready to use immediately
   - It will trigger on the same schedule (Mon/Thu 8 AM ET)
   - Manual runs: `gh workflow run wolfi-base-enhanced.yaml`

5. **Monitor first runs**:
   ```bash
   gh run watch
   gh run list --workflow=wolfi-base-enhanced.yaml
   ```

## Workflow Comparison

| Feature | Old Workflow | New Workflow |
|---------|-------------|--------------|
| apko Execution | Docker container | Native install |
| Build + Push | Separate steps | Single `apko publish` |
| Architecture Handling | Manual per-arch | Automatic multi-arch |
| Package Tracking | No | Yes (in provenance) |
| Test Suite | No | Yes (via Makefile) |
| SBOM Format | SPDX | SPDX (same) |
| Cosign Signing | Yes | Yes (improved) |
| SLSA Provenance | Basic | Enhanced with metadata |
| Security Scanning | Trivy table | SARIF + table |
| GitHub Security Integration | No | Yes (SARIF upload) |
| Build Summary | Basic | Comprehensive |
| Package Update Check | No | Separate workflow |

## New Features Available

### 1. Makefile for Local Development
Provides consistent, easy-to-use commands for local builds and testing.

### 2. Automated Package Updates
New workflow checks for Wolfi package updates weekly:
```bash
# Manually trigger
gh workflow run wolfi-package-updates.yaml
```

### 3. Comprehensive Testing
Full test suite for security, functionality, and package management:
```bash
make test
# Or directly:
./test-wolfi-base.sh
```

### 4. Better Security Integration
- SARIF output uploads to GitHub Security tab
- Enhanced vulnerability tracking
- Automatic issue creation for critical CVEs

### 5. Enhanced Observability
- Detailed build summaries
- Package version tracking
- Better Slack notifications
- Comprehensive logs

## Environment Variables

### Old Scripts
```bash
# Had to edit scripts or pass as arguments
./wolfi-direct-publish.sh custom-tag
```

### New Makefile
```bash
# Clean environment variable interface
IMAGE_TAG=custom-tag make publish
IMAGE_REPO=ghcr.io/myorg/images make publish
APKO_CONFIG=custom.apko.yaml make build
```

## Testing Your Changes

### Before Migration
1. Test the new Makefile:
   ```bash
   cd containers/wolfi-base
   make build
   make load
   make test
   ```

2. Test the new workflow (without publishing):
   ```bash
   # Push to a feature branch and open PR
   # The workflow will build but not push
   git checkout -b test-new-workflow
   git add .
   git commit -m "test: verify new workflow"
   git push origin test-new-workflow
   # Open PR and check workflow runs
   ```

3. Test manual workflow dispatch:
   ```bash
   gh workflow run wolfi-base-enhanced.yaml \
     --field tag=test-$(date +%Y%m%d) \
     --field push_enabled=false
   ```

## Rollback Plan

If you need to rollback to the old workflow:

```bash
# Re-enable old workflow
mv .github/workflows/base-image-build-and-push.yaml.disabled \
   .github/workflows/base-image-build-and-push.yaml

# Disable new workflow
mv .github/workflows/wolfi-base-enhanced.yaml \
   .github/workflows/wolfi-base-enhanced.yaml.disabled

# Commit and push
git add .github/workflows/
git commit -m "rollback: restore old wolfi workflow"
git push
```

## Shell Scripts

The old shell scripts can remain in the repository for reference:
- `wolfi-direct-build.sh` - Replaced by `make build`
- `wolfi-direct-publish.sh` - Replaced by `make publish`
- `wolfi-direct-build-and-publish.sh` - Replaced by `make all && make publish`

These scripts still work but are no longer needed with the Makefile.

## FAQ

### Q: Can I use both workflows simultaneously?
**A**: Yes, but not recommended. They might conflict on the same schedule. If testing, use different schedules or disable one.

### Q: Will the new workflow create the same image tags?
**A**: Yes, `latest`, date-based (`YYYYMMDD`), and commit SHA tags are all created.

### Q: What about SBOM files?
**A**: Generated the same way, in SPDX format, just like before.

### Q: Do I need to update other images?
**A**: No, this migration is only for the Wolfi base image. Other images (node22, postgres, etc.) continue using their existing workflows.

### Q: What if apko isn't installed locally?
**A**: The Makefile automatically detects this and falls back to using the containerized version, just like the old scripts.

### Q: Can I still manually trigger builds?
**A**: Yes! Even easier now:
```bash
# New way
gh workflow run wolfi-base-enhanced.yaml

# Or via GitHub UI
Actions → Enhanced Wolfi Base Image Build & Publish → Run workflow
```

### Q: What about the package update workflow?
**A**: This is entirely new functionality. It runs independently and helps you stay informed about Wolfi package updates.

## Support

If you encounter issues during migration:

1. Check the [README.md](README.md) for detailed documentation
2. Review workflow runs: `gh run list --workflow=wolfi-base-enhanced.yaml`
3. Open an issue: [GitHub Issues](https://github.com/the-mines/sbi/issues)
4. Check logs: `gh run view <run-id> --log`

## Timeline Recommendation

1. **Week 1**: Test new Makefile locally, verify builds work
2. **Week 2**: Enable new workflow alongside old (different schedules)
3. **Week 3**: Monitor both workflows, compare outputs
4. **Week 4**: Disable old workflow, rely fully on new system

## Checklist

- [ ] Reviewed new workflow file
- [ ] Tested Makefile commands locally
- [ ] Verified image builds successfully
- [ ] Ran test suite (`make test`)
- [ ] Checked workflow runs on feature branch
- [ ] Monitored first scheduled run
- [ ] Updated team documentation
- [ ] Disabled old workflow
- [ ] Celebrated! 🎉

---

**Questions?** Open an issue or discussion on GitHub.
