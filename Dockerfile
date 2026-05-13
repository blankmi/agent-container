FROM node:lts-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Layer 1: OS packages — most stable, changes only with base image bumps
RUN apt-get update && apt-get install -y \
    curl git jq ripgrep bash zsh ca-certificates make \
    unzip lsb-release \
 && rm -rf /var/lib/apt/lists/*

# Layer 2: User setup — stable, no deps on tooling
RUN usermod -l agent -d /home/agent -m node && groupmod -n agent node

# Layer 3: npm-based CLIs (root) — semi-stable, version-pinned by npm registry
RUN npm install -g @openai/codex @google/gemini-cli

# Layer 4: cs binary (root) — fetches "latest" from GitHub, keep after npm so
#           npm cache survives a cs release bump
RUN CS_URL=$(curl -s https://api.github.com/repos/blankmi/codesight/releases/latest \
      | jq -r '.assets[] | select(.name == "cs-linux-amd64") | .browser_download_url') && \
    curl -fsSL -o /usr/local/bin/cs "$CS_URL" && \
    chmod +x /usr/local/bin/cs

# Layer 5+: curl-based CLIs (agent) — each in its own layer so one update
#            doesn't invalidate the other
USER agent
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://junie.jetbrains.com/install.sh | bash

# Layer 8: stable agent config — never changes
RUN mkdir -p /home/agent/.codex /home/agent/.gemini

ENV PATH="/home/agent/.local/bin:$PATH"

WORKDIR /workspace
