# Node.js 22 LTS Wolfi-based Image

This document provides detailed information about the Node.js 22 LTS image built on Wolfi.

## Overview

The Node.js 22 LTS image is a minimal, secure container image for running Node.js applications. It is based on the Wolfi Linux distribution and includes Node.js 22 LTS, which is the latest LTS version of Node.js as of its release.

## Security-First Approach

This image follows a **security-first, minimalist approach**:

- **Minimal Attack Surface**: Only essential packages are included, deliberately excluding utilities like busybox that could be used maliciously
- **Least Privilege**: Runs as a non-root user by default
- **Proper Signal Handling**: Includes dumb-init for proper process management
- **No Unnecessary Tools**: Shell utilities, editors, and network tools are intentionally excluded

## Available Tags

- `ghcr.io/the-mines/sbi/node22` - The latest Node.js 22 LTS minimal image
- `ghcr.io/the-mines/sbi/node22-dev` - The latest Node.js 22 LTS image with development tools

## Image Details

- **Base Image**: Wolfi Linux
- **Node.js Version**: 22.x LTS
- **User**: Non-root user `node`
- **Working Directory**: `/app`
- **Default Port**: `3000` (set as `NODE_PORT` environment variable)

## Features

- **Extremely minimal image size** for faster downloads and reduced attack surface
- Runs as a non-root user for enhanced security
- Includes `dumb-init` for proper signal handling
- Supports common Node.js package managers (npm, yarn, pnpm)
- Development variant includes build tools and alternative package managers

## Usage Examples

### Basic Usage

```dockerfile
FROM ghcr.io/the-mines/sbi/node22

WORKDIR /app
COPY . .

CMD ["node", "app.js"]
```

### Multi-stage Build Example

```dockerfile
# Build stage
FROM ghcr.io/the-mines/sbi/node22-dev AS builder
WORKDIR /build
COPY package*.json ./

# Install dependencies
RUN npm ci --omit=dev

# Copy application code
COPY . .

# Production stage
FROM ghcr.io/the-mines/sbi/node22
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /build .

# Set command to run the application
CMD ["node", "server.js"]
```

### Running a Node.js Application

```bash
docker run -p 3000:3000 -v $(pwd):/app ghcr.io/the-mines/sbi/node22 node app.js
```

## Development Features

The development variant (`ghcr.io/the-mines/sbi/node22-dev`) includes additional tools:

- `yarn` - Alternative package manager
- `pnpm` - Fast, disk space efficient package manager
- `corepack` - Tool for managing package managers
- `build-base` - Build tools for compiling native add-ons

## Security Hardening

This image implements several security hardening measures:

- Runs as a non-root user
- Minimal package installation to reduce attack surface
- Excludes common utilities that could be used maliciously
- Regular updates for security patches
- No shell or unnecessary command-line tools

## Comprehensive Testing

The image undergoes comprehensive testing to ensure it meets security and functionality requirements:

- Verification of proper Node.js version and functionality
- Security testing to validate absence of unnecessary tools
- Functional testing with real-world Node.js applications
- Vulnerability scanning

## License

This image is distributed under the Apache 2.0 license.
