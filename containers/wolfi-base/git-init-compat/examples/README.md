# Git-Init Compatibility Examples

This directory contains example Tekton tasks and TaskRuns demonstrating how to
use the git-init compatibility container.

## Files

### git-clone-task-v07.yaml

The original Tekton git-clone task v0.7 that expects the old git-init binary.
This task demonstrates the compatibility issue with modern Git versions.

### git-clone-task-v07-subdirectory.yaml

Modified version of the git-clone task that defaults to cloning into a
subdirectory. This solves workspace permission issues with persistent volumes.
**Recommended for production use.**

### tekton-git-clone-example.yaml

Example TaskRun that uses the git-init compatibility container to successfully
clone a repository using the legacy git-clone task.

```yaml
params:
  - name: gitInitImage
    value: ghcr.io/the-mines/sbi/git-init-compat:latest
```

### tekton-git-clone-small-repo.yaml

Alternative example using a smaller test repository for quick testing.

### pipeline-with-subdirectory.yaml

Complete pipeline example showing how to use the subdirectory approach to avoid
workspace mount permission issues. Includes both the Pipeline and PipelineRun
definitions.

## Running the Examples

1. First, apply the git-clone task:

```bash
kubectl apply -f git-clone-task-v07.yaml
```

2. Then run the example TaskRun:

```bash
kubectl apply -f tekton-git-clone-example.yaml
```

3. Check the status:

```bash
kubectl get taskrun git-clone-compat-test
kubectl logs -l tekton.dev/taskRun=git-clone-compat-test
```

## Testing Different Scenarios

You can modify the TaskRun examples to test different scenarios:

- Different Git repositories
- Various revision types (branches, tags, commits)
- Shallow vs full clones
- Repositories with submodules
- Private repositories (with appropriate auth setup)
