```markdown:containers/python311/README.md
# Python 3.11 Container Image

This container provides a minimal Python 3.11 development environment based on Chainguard's Wolfi base image. It uses a multi-stage build process to create a lightweight runtime image while maintaining development capabilities.

## Features

- Python 3.11 runtime environment
- Based on secure Wolfi base image
- Multi-stage build for minimal image size
- Pre-configured virtual environment
- Ready for production deployments

## Usage

### Basic Usage

Pull and run the container:

```bash
docker pull ghcr.io/the-mines/spellcarver-base-images/spellcarver-python311:latest
docker run -it ghcr.io/the-mines/spellcarver-base-images/spellcarver-python311:latest python
```

### Development Usage

1. Create a `Dockerfile` that extends this image:

```dockerfile
FROM ghcr.io/the-mines/spellcarver-base-images/spellcarver-python311:latest

# Copy your application
COPY . /app/

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Run your application
CMD ["python", "your_script.py"]
```

2. Build and run your application:

```bash
docker build -t my-python-app .
docker run my-python-app
```

### Using with Docker Compose

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - .:/app
    command: python your_script.py
```

## Customization

### Installing Additional Packages

To install additional system packages, add them in the runtime stage:

```dockerfile
FROM ghcr.io/the-mines/spellcarver-base-images/spellcarver-python311:latest

RUN apk add --no-cache package-name
```

### Installing Python Packages

To install Python packages, you can either:

1. Mount a requirements.txt file:
```bash
docker run -v $(pwd)/requirements.txt:/app/requirements.txt ghcr.io/the-mines/spellcarver-base-images/spellcarver-python311:latest pip install -r requirements.txt
```

2. Install directly using pip:
```bash
docker run ghcr.io/the-mines/spellcarver-base-images/spellcarver-python311:latest pip install package-name
```

## Development

### Building the Image Locally

```bash
docker build -t python311 .
```

### Running Tests

```bash
docker run python311 python -m pytest
```

## Security

This image:
- Uses Chainguard's Wolfi base image for enhanced security
- Implements multi-stage builds to reduce attack surface
- Runs as non-root by default (when extending the image)