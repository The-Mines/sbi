# Git-Init Compatibility Container

This container provides a compatibility layer for legacy Tekton git-clone tasks
that expect the old `git-init` binary behavior. It solves the "dubious
ownership" error that occurs when using modern Git versions in containerized
environments.

## Problem Statement

Starting with Git 2.35.2, Git introduced stricter ownership checks to prevent
security vulnerabilities. When Git detects that a repository is owned by a
different user than the one running the command, it fails with:

```
fatal: detected dubious ownership in repository at '/workspace/output'
```

This is particularly problematic in Tekton pipelines where:

- Workspaces are typically owned by root
- Containers run as non-root users (e.g., UID 65532)
- The old Tekton git-clone tasks (v0.7 and earlier) don't handle this scenario

## Solution

This compatibility container provides a multi-layered approach:

1. **Git Binary Wrapper**: Replaces `/usr/bin/git` with a wrapper script that
   automatically configures `git config --global --add safe.directory "*"`
   before executing any git command.

2. **Go Binary Compatibility**: Provides `/ko-app/git-init` that mimics the old
   Tekton git-init behavior, accepting the same command-line arguments.

3. **Entrypoint Script**: Includes an entrypoint that can be used when not
   constrained by Tekton's script override.

## Usage

### With Tekton git-clone v0.7 tasks

Simply override the `gitInitImage` parameter:

```yaml
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: clone-repo
spec:
  taskRef:
    name: git-clone
  params:
    - name: url
      value: https://github.com/your-org/your-repo
    - name: gitInitImage
      value: ghcr.io/the-mines/sbi/git-init-compat:latest
  workspaces:
    - name: output
      emptyDir: {}
```

### Direct Usage

The container can also be used directly:

```bash
docker run --rm -v $(pwd):/workspace ghcr.io/the-mines/sbi/git-init-compat:latest \
  -url=https://github.com/octocat/Hello-World \
  -path=/workspace/output \
  -revision=main
```

## Architecture

```
/usr/bin/git          → Shell wrapper that adds safe.directory config
/usr/bin/git.real     → Original git binary
/ko-app/git-init      → Go binary that handles Tekton parameters
/usr/local/bin/entrypoint.sh → Optional entrypoint for non-Tekton usage
```

## Building

```bash
# Build locally
make build

# Build and push multi-arch image
make build-multiarch

# Run tests
make test
```

## Supported Parameters

The git-init binary supports all parameters from the original Tekton
implementation:

- `-url`: Repository URL to clone
- `-revision`: Branch, tag, or commit to checkout
- `-refspec`: Refspec to fetch
- `-path`: Directory to clone into
- `-depth`: Clone depth for shallow clones
- `-submodules`: Whether to initialize submodules
- `-sslVerify`: SSL verification setting
- `-sparseCheckoutDirectories`: Sparse checkout patterns

## Why This Was Necessary

1. **Legacy Support**: Many organizations have pipelines using older Tekton
   catalog tasks that can't be easily updated.

2. **Security vs Compatibility**: While Git's ownership checks improve security,
   they break containerized workflows where workspace ownership doesn't match
   the running user.

3. **Tekton Constraints**: When Tekton uses a `script` field in a task, it
   overrides the container's ENTRYPOINT, making traditional solutions
   ineffective.

## Security Considerations

This container uses `safe.directory '*'` which disables Git's ownership checks.
While this solves the compatibility issue, it does reduce security. This
trade-off is acceptable in ephemeral CI/CD environments where:

- Containers are short-lived
- Workspaces contain only the code being built
- The environment is already trusted

For production use, consider updating to newer Tekton tasks that handle
ownership properly.

## Version History

- v3.0.1 - Fixed git wrapper to use cp instead of mv
- v3.0.0 - Added git wrapper solution
- v2.0.0 - Added entrypoint script approach
- v1.0.0 - Initial implementation

## License

This container is part of the Spellcarver Base Images (SBI) project.
