# Troubleshooting Guide

## Common Issues and Solutions

### 1. Workspace Directory Permission Issues

**Problem**: The git-init tool expects an empty directory but the workspace
mount point (`/workspace/output/`) cannot be completely cleared due to
Kubernetes volume mount restrictions. You may see errors like:

- `Permission denied` when trying to remove `lost+found`
- `Directory not empty` errors
- Failed cleanup operations

**Root Cause**: Kubernetes persistent volumes often contain system directories
(like `lost+found`) that cannot be removed by non-root users.

**Solutions**:

#### Option A: Use Subdirectory Approach (Recommended)

Clone into a subdirectory instead of the workspace root:

```yaml
params:
  - name: subdirectory
    value: source # Clone into /workspace/output/source
```

Use the provided `git-clone-subdirectory` task which defaults to using a
subdirectory.

#### Option B: Ignore Cleanup Errors

Modify your pipeline to continue even if cleanup fails:

```bash
cleandir() {
  if [ -d "${CHECKOUT_DIR}" ] ; then
    rm -rf "${CHECKOUT_DIR:?}"/* 2>/dev/null || true
    rm -rf "${CHECKOUT_DIR}"/.[!.]* 2>/dev/null || true
    rm -rf "${CHECKOUT_DIR}"/..?* 2>/dev/null || true
  fi
}
```

#### Option C: Use EmptyDir Volumes

For non-persistent data, use emptyDir volumes which don't have system
directories:

```yaml
workspaces:
  - name: output
    emptyDir: {}
```

### 2. Git Dubious Ownership Errors

**Problem**: Git fails with "detected dubious ownership in repository" error.

**Solution**: This is already handled by the git-init-compat container, but if
you still see issues:

1. Ensure you're using the latest version:
   `ghcr.io/the-mines/sbi/git-init-compat:latest`
2. Check that the git wrapper is working:
   `kubectl exec <pod> -- git config --get-regexp safe.directory`

### 3. Private Repository Access

**Problem**: Cannot clone private repositories.

**Solutions**:

#### Using SSH Keys:

```yaml
workspaces:
  - name: ssh-directory
    secret:
      secretName: git-ssh-secret
```

#### Using Basic Auth:

```yaml
workspaces:
  - name: basic-auth
    secret:
      secretName: git-basic-auth
```

### 4. Image Pull Errors

**Problem**: Cannot pull the git-init-compat image.

**Solution**: Add imagePullSecrets to your ServiceAccount:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pipeline-sa
imagePullSecrets:
  - name: ghcr-token
```

### 5. APKO Build Task Issues

**Problem**: APKO build task changed from script to command format.

**Solution**: Ensure your APKO task uses the command format:

```yaml
steps:
  - name: build
    image: cgr.dev/chainguard/apko
    command: ["apko"]
    args: ["build", "$(params.config)", "$(params.image-name)", "image.tar"]
```

## Best Practices

1. **Always use subdirectories** for git clones in persistent workspaces
2. **Test with emptyDir** first to isolate permission issues
3. **Use explicit paths** in subsequent tasks:
   `$(workspaces.source.path)/source/`
4. **Monitor workspace usage** to avoid filling up volumes
5. **Clean up workspaces** between pipeline runs when possible

## Debug Commands

```bash
# Check workspace permissions
kubectl exec <pod> -- ls -la /workspace/output/

# Test git configuration
kubectl exec <pod> -- git config --list --global

# Verify git-init binary
kubectl exec <pod> -- /ko-app/git-init -help

# Check for system directories
kubectl exec <pod> -- find /workspace/output -name "lost+found"
```
