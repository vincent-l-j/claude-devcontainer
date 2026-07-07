# base/Containerfile
#
# Claude Code sandbox - base image.
# Mounts the current project directory at /app.
#
# Build: ./sandbox.sh build
# Run:   ./sandbox.sh run --dir ~/projects/my-project

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# --- Bootstrap packages (needed to install Claude Code CLI) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# --- Unprivileged user ---
# HOST_UID must match the host user's uid so bind-mounted files are
# already owned by claude - no chown needed at runtime.
ARG HOST_UID=1000
RUN useradd -ms /bin/bash -u ${HOST_UID} claude && \
    mkdir -p /home/claude/.local/bin && \
    chown -R claude:claude /home/claude
USER claude

# --- Claude Code CLI (installed as the claude user so it lands in ~/.local/bin) ---
# This layer is intentionally placed before the common system packages so that
# adding new packages does not invalidate this slow download step.
RUN curl -fsSL https://claude.ai/install.sh | bash

USER root
RUN cp /home/claude/.local/bin/claude /usr/local/bin/claude && \
    chmod +x /usr/local/bin/claude

# --- Node.js 22 (LTS) via NodeSource ---
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Common system packages ---
# Add new packages here. Layers above (including the CLI install) stay cached.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    vim \
    unzip \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

RUN git config --system user.email "claude@sandbox" && \
    git config --system user.name "claude"

WORKDIR /app

USER claude

ENV PATH="/home/claude/.local/bin:${PATH}"
ENV EDITOR=vim

CMD ["claude"]
