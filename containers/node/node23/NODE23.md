# Node.js 23 SBI

This directory contains the Dockerfiles and build tools for creating Node.js 23 Spellcarver Base Images (SBI).

## Images

This directory produces the following images:

- `node23` - Minimal Node.js 23 runtime image
- `node23-dev` - Development image with Node.js 23 and common development tools

## Build Instructions

The included Makefile provides several targets for building and managing the images:

```shell
# Build both images
make build

# Build only the runtime image
make build-base

# Build only the development image
make build-dev

# Show all available options
make help
```

## Dockerfiles

- `Dockerfile.node23` - Minimal Node.js 23 runtime image
- `Dockerfile.node23-dev` - Development image with Node.js 23 and common development tools

## Usage Examples

### Runtime Image

The runtime image is designed for running Node.js applications in production