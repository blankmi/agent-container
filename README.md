# agent-container

Base image and project template for running AI coding agents (Claude Code, Codex CLI, Junie) in isolated Docker containers with persistent auth state.

## Initial Setup

Build the base image (tagged with today's date as `local/agent-base:YYYY-MM-DD`):

```bash
./build.sh
```

## New Project Setup

Copy the template into your project root:

```bash
cp -r /path/to/agent-container/template/. your-project/ && chmod +x your-project/agent
```

Then edit `your-project/.agent/Dockerfile` to pin the base image tag and add project-specific runtimes.

To let a coding agent configure the environment for you, use the included `template/.agent/AGENT.md` as your prompt. The agent will inspect the repository, determine required runtimes and tooling, and update the Dockerfile accordingly.

## Usage

```bash
./agent claude    # start Claude Code
./agent codex     # start Codex CLI
./agent junie     # start Junie
./agent bash      # open a shell
```

## Persistent Auth

Agent config is stored in named Docker volumes (`claude-config`, `codex-config`, `junie-config`). Log in once; sessions persist across container restarts.

## Update Strategy

Rebuild the base image with a new date tag:

```bash
docker build --pull --no-cache \
  -t local/agent-base:$(date +%Y-%m-%d) \
  /path/to/agent-container
```

Then update the FROM line in each project's `.agent/Dockerfile` and rebuild:

```bash
docker compose -f .agent/compose.yaml build
```

Use date-based tags (e.g. `2026-05-20`) rather than `latest` for reproducibility.

## Network Configuration

By default, the agent container can access the internet and any Docker services attached to the same Docker network.

### Access Existing Project Containers

If your project already runs services such as:

- PostgreSQL
- MySQL
- Redis
- Elasticsearch
- Mailhog
- Selenium

attach the agent container to the same external Docker network.

Create a shared network once:

```bash
docker network create myproject-dev-net
```

Attach existing services to that network:

```yaml
services:
  db:
    image: postgres:16
    networks:
      - dev-net

networks:
  dev-net:
    external: true
    name: myproject-dev-net
```

Then attach the agent container to the same network in `.agent/compose.yaml`:

```yaml
services:
  agent:
    networks:
      - dev-net

networks:
  dev-net:
    external: true
    name: myproject-dev-net
```

Inside the agent container, services are reachable by container/service name:

```bash
psql -h db -U app app
```

### Access Services Running on macOS

To access services running directly on the host Mac from inside the container, use:

```text
host.docker.internal
```

Example:

```bash
curl http://host.docker.internal:8080
```

Do not use `localhost` for host services inside containers. Inside Docker, `localhost` always refers to the container itself.

### Disable Network Access

To completely disable networking for an agent session:

```yaml
network_mode: none
```

## Security

The compose setup drops all Linux capabilities and prevents privilege escalation. Agent auth state is kept in named Docker volumes, never baked into the image.
