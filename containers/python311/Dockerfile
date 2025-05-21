# Build stage
FROM ghcr.io/the-mines/sbi/wolfi:latest as builder

# Install Python 3.11 and development tools with explicit virtual package handling
RUN apk update && \
    apk add --no-cache --virtual .python-build-deps build-base && \
    apk add --no-cache --update-cache \
            --repository=https://packages.wolfi.dev/os \
            python-3.11 \
            python-3.11-dev \
            py3-pip && \
    apk fix
# Set Python 3.11 as the default without conflicting with system Python
RUN mkdir -p /usr/local/bin && \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python3 && \
    ln -sf /usr/bin/pip3.11 /usr/local/bin/pip3 && \
    ln -sf /usr/bin/pip3.11 /usr/local/bin/pip

# Update PATH to prioritize our symlinks
ENV PATH="/usr/local/bin:$PATH"

WORKDIR /app

# Create and activate virtual environment with explicit Python path
RUN /usr/bin/python3.11 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Copy and install requirements if you have any
# COPY requirements.txt .
# RUN pip install -r requirements.txt

# Runtime stage
FROM cgr.dev/chainguard/wolfi-base:latest

# Install only Python 3.11 runtime with explicit version
RUN apk update && \
    apk add --no-cache --update-cache \
            --repository=https://packages.wolfi.dev/os \
            python-3.11=3.11.11-r5 && \
    apk fix

# Set up symlinks in /usr/local to avoid conflicting with system Python
RUN mkdir -p /usr/local/bin && \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python3

# Update PATH to prioritize our symlinks
ENV PATH="/usr/local/bin:$PATH"

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Copy your application code
# COPY . .

# Set the default command
CMD ["/usr/bin/python3.11"]