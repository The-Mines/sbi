# Build stage
FROM cgr.dev/chainguard/wolfi-base:latest as builder

# Install Python 3.11 and development tools
RUN apk update && \
    apk add python-3.11 py3-pip build-base python3-dev

# Set Python 3.11 as the default
RUN ln -sf /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3

WORKDIR /app

# Create and activate virtual environment
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Copy and install requirements if you have any
# COPY requirements.txt .
# RUN pip install -r requirements.txt

# Runtime stage
FROM cgr.dev/chainguard/wolfi-base:latest

# Install only Python 3.11 runtime
RUN apk update && \
    apk add python-3.11 && \
    ln -sf /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Copy your application code
# COPY . .

# Set the default command
CMD ["python"]