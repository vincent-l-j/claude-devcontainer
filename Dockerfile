FROM mcr.microsoft.com/devcontainers/base:ubuntu24.04@sha256:4bcb1b466771b1ba1ea110e2a27daea2f6093f9527fb75ee59703ec89b5561cb

# --- Bootstrap packages (needed to install Claude Code CLI) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    # firewall networking
    ipset \
    iptables \
    dnsutils \
    aggregate \
    && rm -rf /var/lib/apt/lists/*

# Create directories and set ownership (combined for fewer layers)
RUN mkdir -p /commandhistory /workspace /home/vscode/.claude && \
  touch /commandhistory/.bash_history && \
  touch /commandhistory/.zsh_history && \
  chown -R vscode:vscode /commandhistory /workspace /home/vscode/.claude

WORKDIR /workspace

# Switch to non-root user for remaining setup
USER vscode

# Set PATH early so claude and other user-installed binaries are available
ENV PATH="/home/vscode/.local/bin:$PATH"

# --- Claude Code CLI (installed as the claude user so it lands in ~/.local/bin) ---
# This layer is intentionally placed before the common system packages so that
# adding new packages does not invalidate this slow download step.
RUN curl -fsSL https://claude.ai/install.sh | bash

USER root
RUN cp /home/vscode/.local/bin/claude /usr/local/bin/claude && \
    chmod +x /usr/local/bin/claude

# --- Common system packages ---
# Add new packages here. Layers above (including the CLI install) stay cached.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    vim \
    unzip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN git config --global --add safe.directory '*'

USER vscode

ENV EDITOR=vim
