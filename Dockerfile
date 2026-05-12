FROM node:lts-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git jq ripgrep bash zsh ca-certificates make \
    unzip lsb-release \
 && rm -rf /var/lib/apt/lists/*

# npm-based CLIs: install as root so binaries land in /usr/local/bin
RUN npm install -g @openai/codex @google/gemini-cli

# Rename node → agent before curl-based installs
RUN usermod -l agent -d /home/agent -m node && groupmod -n agent node

# curl-based CLIs: run as agent so full install (binary + data) goes to /home/agent/.local
USER agent
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://junie.jetbrains.com/install.sh | bash

# Pre-create config dirs for npm-based tools so named volumes mount with agent ownership
RUN mkdir -p /home/agent/.codex /home/agent/.gemini

ENV PATH="/home/agent/.local/bin:$PATH"

WORKDIR /workspace
