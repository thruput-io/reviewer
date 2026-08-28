# Antigravity (agy) + Azure DevOps & Git MCP Server Container
# Base image with Node.js 20 on Debian Bookworm
FROM node:20-bookworm-slim

LABEL maintainer="Antigravity Team"
LABEL description="Antigravity CLI (agy) environment with Azure DevOps and Git MCP servers for PR workflows"

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV AGY_HOME=/home/agyuser
ENV WORKSPACE_DIR=/workspace

# Install system dependencies: Git, Python 3, pip, venv, curl, jq, ca-certificates, openssh-client
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    openssh-client \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install official Azure DevOps MCP server globally via npm
RUN npm install -g @azure-devops/mcp

# Install Git MCP server via pip
# Using --break-system-packages for clean global install in container environment
RUN pip3 install --no-cache-dir --break-system-packages mcp-server-git

# Install Antigravity CLI (agy)
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- -d /usr/local/bin \
    && chmod +x /usr/local/bin/agy \
    && agy --version || true

ENV PATH="/usr/local/bin:${AGY_HOME}/.local/bin:${PATH}"

# Configure non-root user 'agyuser' (UID/GID 1000) and set up workspace and config directories
RUN if id node >/dev/null 2>&1; then \
        usermod -l agyuser -d ${AGY_HOME} -m node && \
        groupmod -n agyuser node; \
    else \
        groupadd -g 1000 agyuser && \
        useradd -u 1000 -g agyuser -m -s /bin/bash agyuser; \
    fi \
    && mkdir -p ${WORKSPACE_DIR} \
    && mkdir -p ${AGY_HOME}/.gemini/config \
    && mkdir -p ${AGY_HOME}/.gemini/antigravity-cli \
    && mkdir -p ${AGY_HOME}/.config \
    && chown -R agyuser:agyuser ${AGY_HOME} ${WORKSPACE_DIR}

# Copy scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bin/review-pr /usr/local/bin/review-pr
COPY bin/create-pr /usr/local/bin/create-pr
COPY bin/pr-summary /usr/local/bin/pr-summary

# Make all custom binaries executable
RUN chmod +x /usr/local/bin/entrypoint.sh \
    /usr/local/bin/review-pr \
    /usr/local/bin/create-pr \
    /usr/local/bin/pr-summary

# Set working directory to workspace
WORKDIR ${WORKSPACE_DIR}

# Switch to non-root user
USER agyuser

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["agy"]
