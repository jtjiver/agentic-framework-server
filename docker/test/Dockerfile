# ASW Framework Test Environment
# Ubuntu-based to match VPS environment
FROM ubuntu:22.04 as base

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install base system packages
RUN apt-get update && apt-get install -y \
    # Essential build tools
    build-essential \
    curl \
    wget \
    git \
    vim \
    nano \
    # System utilities matching VPS setup
    sudo \
    htop \
    tree \
    jq \
    unzip \
    bash-completion \
    tmux \
    # Diagnostic and monitoring tools
    iotop \
    nethogs \
    sysstat \
    lsof \
    strace \
    tcpdump \
    nmap \
    dstat \
    net-tools \
    # Security tools
    ufw \
    fail2ban \
    # Web server tools
    nginx \
    # SSL tools
    certbot \
    # Database clients for testing
    postgresql-client \
    sqlite3 \
    # Python development
    python3 \
    python3-pip \
    python3-venv \
    # Additional utilities
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (matching VPS setup)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install 1Password CLI
RUN curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    tee /etc/apt/sources.list.d/1password.list \
    && apt-get update \
    && apt-get install -y 1password-cli

# Install GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -O- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Install Docker CLI for testing docker-related scripts
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin

# Install testing frameworks
RUN npm install -g \
    jest \
    mocha \
    tap \
    bats \
    && pip3 install \
    pytest \
    pytest-cov \
    pytest-mock \
    shellcheck-py

# Install BATS (Bash Automated Testing System) from source for latest version
RUN git clone https://github.com/bats-core/bats-core.git /tmp/bats \
    && cd /tmp/bats \
    && ./install.sh /usr/local \
    && rm -rf /tmp/bats

# Install additional BATS helpers
RUN git clone https://github.com/bats-core/bats-support.git /opt/bats-support \
    && git clone https://github.com/bats-core/bats-assert.git /opt/bats-assert \
    && git clone https://github.com/bats-core/bats-file.git /opt/bats-file

# Create test user matching VPS setup
RUN useradd -m -s /bin/bash -G sudo cc-user \
    && echo 'cc-user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/cc-user \
    && chmod 440 /etc/sudoers.d/cc-user

# Set up test directories
RUN mkdir -p /opt/test-results /opt/asw \
    && chown -R cc-user:cc-user /opt/test-results /opt/asw

# Install shellcheck directly
RUN apt-get update && apt-get install -y shellcheck && rm -rf /var/lib/apt/lists/*

# Test environment stage
FROM base as test
USER cc-user
WORKDIR /opt/asw

# Copy test configuration
COPY --chown=cc-user:cc-user docker/test/test-config /home/cc-user/.test-config

# Set up bash environment for testing
RUN echo 'export PATH="/home/cc-user/.local/bin:$PATH"' >> /home/cc-user/.bashrc \
    && echo 'export BATS_LIB_PATH="/opt/bats-support:/opt/bats-assert:/opt/bats-file"' >> /home/cc-user/.bashrc \
    && echo 'source ~/.test-config 2>/dev/null || true' >> /home/cc-user/.bashrc

# Isolated test environment stage (more restrictive)
FROM test as isolated-test
USER cc-user

# Remove some tools that shouldn't be available in isolated tests
USER root
RUN apt-get update && apt-get remove -y \
    docker-ce-cli \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*
USER cc-user

LABEL org.opencontainers.image.title="ASW Framework Test Environment"
LABEL org.opencontainers.image.description="Ubuntu-based testing environment for ASW Framework utilities and setup scripts"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="ASW Framework Team"