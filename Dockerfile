FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV AGY_HOME=/home/agyuser
ENV WORKSPACE_DIR=/workspace

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

RUN npm install -g @azure-devops/mcp

RUN pip3 install --no-cache-dir --break-system-packages mcp-server-git

RUN curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- -d /usr/local/bin \
    && chmod +x /usr/local/bin/agy \
    && agy --version || true

ENV PATH="/usr/local/bin:${AGY_HOME}/.local/bin:${PATH}"

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

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bin/review-pr /usr/local/bin/review-pr

RUN chmod +x /usr/local/bin/entrypoint.sh \
    /usr/local/bin/review-pr

WORKDIR ${WORKSPACE_DIR}

USER agyuser

RUN npx --yes @agentplugins/cli add thruput-io/agents

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["review-pr"]
