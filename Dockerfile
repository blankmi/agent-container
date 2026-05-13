FROM node:lts-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Layer 1: OS packages — most stable, changes only with base image bumps
RUN apt-get update && apt-get install -y \
    curl git jq ripgrep bash zsh ca-certificates make \
    unzip lsb-release \
 && rm -rf /var/lib/apt/lists/*

# Layer 2: User setup — stable, no deps on tooling
RUN usermod -l agent -d /home/agent -m node && groupmod -n agent node

# Layer 3: cs binary (root) — fetches "latest" from GitHub
RUN CS_URL=$(curl -s https://api.github.com/repos/blankmi/codesight/releases/latest \
      | jq -r '.assets[] | select(.name == "cs-linux-amd64") | .browser_download_url') && \
    curl -fsSL -o /usr/local/bin/cs "$CS_URL" && \
    chmod +x /usr/local/bin/cs

# Layer 4: entrypoint script — sets git identity from host env, wires Claude
#           credential symlinks when the shared volume is mounted
RUN printf '#!/bin/sh\n\
[ -n "$GIT_USER_NAME" ] && git config --global user.name "$GIT_USER_NAME"\n\
[ -n "$GIT_USER_EMAIL" ] && git config --global user.email "$GIT_USER_EMAIL"\n\
if [ -d /home/agent/.claude-shared ]; then\n\
  mkdir -p /home/agent/.claude-shared/.claude\n\
  [ -e /home/agent/.claude-shared/.claude.json ] || touch /home/agent/.claude-shared/.claude.json\n\
  [ -L /home/agent/.claude.json ] || rm -f  /home/agent/.claude.json\n\
  [ -L /home/agent/.claude      ] || rm -rf /home/agent/.claude\n\
  ln -sf  /home/agent/.claude-shared/.claude.json /home/agent/.claude.json\n\
  ln -sfn /home/agent/.claude-shared/.claude      /home/agent/.claude\n\
fi\n\
exec "$@"\n' > /usr/local/bin/docker-entrypoint.sh \
 && chmod +x /usr/local/bin/docker-entrypoint.sh

USER agent
ENV PATH="/home/agent/.local/bin:$PATH"

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
