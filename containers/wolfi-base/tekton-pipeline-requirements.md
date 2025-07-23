# Tekton Pipeline AI Assistant Template

## Overview

This document provides specifications for an AI assistant to create a Tekton
Pipeline that automates the daily building and publishing of the Wolfi base
container image using the `apko` tool with cron scheduling.

**Target Registry:** ghcr.io/the-mines/sbi/wolfi **Secret Name:** ghcr-token
**Package URL:**
https://github.com/orgs/The-Mines/packages/container/package/sbi%2Fwolfi

## Core Architecture

### 1. Main Pipeline Controller

The top-level orchestrator that handles the daily build and publish workflow.

```yaml
# tekton-wolfi-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: wolfi-base-daily-build
  namespace: tekton-pipelines
spec:
  description: Daily automated build and publish of Wolfi base image
  params:
    - name: registry
      type: string
      default: "ghcr.io/the-mines/sbi/wolfi" # Full registry path
    - name: source-repo
      type: string
      default: "https://github.com/the-mines/sbi.git"
    - name: apko-config-path
      type: string
      default: "containers/wolfi-base/wolfi-direct.apko.yaml"
    - name: tag
      type: string
      default: "latest"
  workspaces:
    - name: source-workspace
    - name: docker-credentials # For registry authentication
```

### 2. Required Tekton Components

#### Task Definitions

```yaml
# Essential tasks the AI should create:
- git-clone-task # Fetch source repository
- prepare-tags-task # Generate date-based and other tags
- apko-build-publish-task # Combined build and publish with apko
- validate-image-task # Pull and verify published image
- notification-task # Success/failure notifications
```

#### CronJob Configuration

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: wolfi-daily-build
spec:
  schedule: "0 6 * * *" # Daily at 6 AM UTC
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: tekton-pipeline-sa
```

### 3. Current Implementation Analysis

#### File Structure Context

```
containers/wolfi-base/
├── wolfi-direct.apko.yaml              # apko configuration
├── wolfi-direct-build.sh               # local build script
├── wolfi-direct-publish.sh             # local publish script
└── wolfi-direct-build-and-publish.sh   # combined script
```

#### Key Requirements from Analysis

##### apko Configuration (`wolfi-direct.apko.yaml`)

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

##### Build Process Translation

```bash
# Current shell command:
apko build wolfi-direct.apko.yaml wolfi-direct:latest wolfi-direct-multiarch.tar --arch x86_64,aarch64

# Tekton task equivalent needed:
- name: apko-build-publish
  image: cgr.dev/chainguard/apko:latest
  script: |
    # Note: apko publish combines build and push in one efficient operation
    apko publish $(workspaces.source-workspace.path)/$(params.apko-config-path) \
      $(params.registry):$(params.tag) \
      --arch x86_64,aarch64 --sbom --sbom-formats spdx --vcs
```

##### Publish Process Translation

```bash
# Current shell command:
apko publish wolfi-direct.apko.yaml ghcr.io/the-mines/sbi/wolfi:TAG \
  --arch x86_64,aarch64 --sbom --sbom-formats spdx --vcs

# Authentication via workspace mount:
- name: apko-publish-with-auth
  workspaces:
    - name: docker-credentials
      mountPath: /workspace/docker-config
  env:
    - name: DOCKER_CONFIG
      value: /workspace/docker-config
  script: |
    # Credentials are accessed from the mounted workspace
    apko publish $(workspaces.source-workspace.path)/$(params.apko-config-path) \
      $(params.registry):$(params.tag) \
      --arch x86_64,aarch64 --sbom --sbom-formats spdx --vcs
```

### 4. Authentication & Security Setup

```yaml
# Required Kubernetes resources the AI should create:

# 1. Secret for GHCR authentication
apiVersion: v1
kind: Secret
metadata:
  name: ghcr-token
  annotations:
    tekton.dev/docker-0: ghcr.io
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>

# 2. Service Account with proper permissions (modern approach - no direct secret linkage)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tekton-pipeline-sa
# Note: Secrets will be mounted via workspace in PipelineRun for better security

# 3. Role for pipeline execution (namespace-scoped for security)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tekton-pipeline-role
  namespace: tekton-pipelines
rules:
  - apiGroups: [""]
    resources: ["pods", "persistentvolumeclaims"]
    verbs: ["create", "get", "list", "delete"]
```

### 5. Environment Variables & Configuration

```yaml
# Configuration the AI should implement:
# Parameters to be defined in Pipeline (not hardcoded):
pipeline_parameters:
  - name: registry
    default: "ghcr.io/the-mines/sbi/wolfi" # Full path including image name
  - name: source-repo
    default: "https://github.com/the-mines/sbi.git" # Parameterized for migration
  - name: apko-config-path
    default: "containers/wolfi-base/wolfi-direct.apko.yaml" # Relative to workspace
  - name: tag
    default: "latest" # Can be overridden for date tags

# Absolute paths for migration reference (not used in pipeline):
migration_reference_paths:
  - /Users/walterday/Git/MerlinMines/Apps/sbi/containers/wolfi-base/wolfi-direct.apko.yaml
  - /Users/walterday/Git/MerlinMines/Apps/sbi/containers/wolfi-base/wolfi-direct-build.sh
  - /Users/walterday/Git/MerlinMines/Apps/sbi/containers/wolfi-base/wolfi-direct-publish.sh
  - /Users/walterday/Git/MerlinMines/Apps/sbi/containers/wolfi-base/wolfi-direct-build-and-publish.sh

# Dynamic tagging strategy:
tag_generation:
  - latest # Always update latest
  - $(date +%Y%m%d) # Date-based tags: 20240715
  - $(git rev-parse --short HEAD) # Git commit hash
```

### 6. Workspace & Storage Requirements

```yaml
# PVC specifications the AI should create:
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wolfi-build-workspace
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi # Sufficient for source + build artifacts
```

### 7. Success Criteria & Validation

```yaml
# The pipeline must achieve:
success_criteria:
  - Multi-architecture image published (x86_64, aarch64)
  - SBOM files generated in SPDX format
  - Image tagged with date and latest
  - Build logs captured and accessible
  - Failure notifications sent to configured channels
  - Build artifacts cleaned up after successful publish

# Validation steps:
validation_tasks:
  - name: validate-image
    script: |
      # Pull and test the published image
      docker pull $(params.registry)/$(params.image-name):$(params.tag)
      docker run --rm $(params.registry)/$(params.image-name):$(params.tag) apk list --installed
```

### 8. Multi-Tag Publishing Strategy

```yaml
# Task to generate multiple tags
prepare-tags-task:
  results:
    - name: date-tag
      description: Date-based tag (e.g., 20250706)
    - name: commit-tag
      description: Git commit short hash
  script: |
    #!/bin/bash
    # Generate date tag
    echo -n "$(date +%Y%m%d)" > $(results.date-tag.path)

    # Generate commit tag (from cloned source)
    cd $(workspaces.source.path)
    echo -n "$(git rev-parse --short HEAD)" > $(results.commit-tag.path)

# Pipeline section for parallel tag publishing
pipeline_tasks:
  - name: publish-latest
    taskRef:
      name: apko-build-publish
    params:
      - name: tag
        value: "latest"

  - name: publish-date
    taskRef:
      name: apko-build-publish
    params:
      - name: tag
        value: "$(tasks.prepare-tags.results.date-tag)"
    runAfter:
      - prepare-tags
```

### 9. Error Handling & Recovery

```yaml
# Error handling patterns the AI should implement:
error_handling:
  - retry_policy:
      attempts: 3
      backoff: exponential
  - cleanup_on_failure: true
  - notification_on_failure: true
  - preserve_logs: true

# Recovery scenarios:
recovery_patterns:
  - network_failures: "Retry with exponential backoff"
  - authentication_failures: "Alert and require manual intervention"
  - build_failures: "Preserve artifacts for debugging"
  - publish_failures: "Retry publish step only"
```

## Implementation Guidelines for AI

### 1. Start with Core Pipeline

Begin with basic git clone -> build -> publish flow, then add complexity.

### 2. Use Tekton Best Practices

- Implement proper workspace management
- Use parameterized tasks for reusability
- Follow Tekton security guidelines
- Implement proper resource limits

### 3. Security Considerations

- Validate all file paths within workspace
- Implement proper RBAC permissions
- Secure credential management
- Enable security scanning integration

### 4. Performance Optimization

- Implement efficient workspace usage
- Cache apko tool and dependencies
- Optimize multi-arch build process
- Monitor resource consumption

### 5. Monitoring & Observability

- Implement structured logging
- Add metrics collection
- Create dashboard integration
- Enable alerting on failures

## Expected Deliverables

The AI assistant should create the following Tekton resources:

```yaml
# Complete file list to generate:
tekton-resources/
├── pipeline/
│   ├── wolfi-base-pipeline.yaml           # Main pipeline definition
│   └── pipeline-run-template.yaml         # Template for manual runs
├── tasks/
│   ├── git-clone-task.yaml                # Source checkout
│   ├── apko-build-task.yaml               # Image building
│   ├── apko-publish-task.yaml             # Registry publishing
│   └── notification-task.yaml             # Success/failure notifications
├── triggers/
│   ├── cronjob-trigger.yaml               # Daily cron scheduling
│   └── manual-trigger.yaml                # Manual execution trigger
├── rbac/
│   ├── service-account.yaml               # Pipeline service account
│   ├── cluster-role.yaml                  # Required permissions
│   └── role-binding.yaml                  # Permission bindings
├── storage/
│   └── workspace-pvc.yaml                 # Build workspace storage
└── secrets/
    └── ghcr-token-template.yaml     # Registry authentication template
```

## Usage Example

```bash
# Deploy the pipeline
kubectl apply -f tekton-resources/


# The pipeline will automatically run daily at 6 AM UTC
# Manual execution:
tkn pipeline start wolfi-base-daily-build \
  --param registry=ghcr.io/the-mines/sbi/wolfi \
  --param source-repo=https://github.com/the-mines/sbi.git \
  --param tag=manual-$(date +%Y%m%d) \
  --workspace name=source-workspace,claimName=wolfi-build-workspace \
  --workspace name=docker-credentials,secret=ghcr-token
```

## Next Steps for AI Implementation

1. Generate all Tekton YAML resources
2. Create deployment scripts and documentation
3. Implement monitoring and alerting
4. Add integration tests
5. Create troubleshooting guide
6. Extend with additional security scanning integration

This template provides the complete specification for building a
production-ready Tekton pipeline that replicates and enhances the current manual
apko build process with automated daily scheduling, proper error handling, and
enterprise-grade security practices.
