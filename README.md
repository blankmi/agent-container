# agent-container

Per-agent base images and a project template for running AI coding agents (Claude Code, Codex CLI, Junie) in isolated Docker containers. Logins are shared across projects via external Docker volumes; everything else stays ephemeral so concurrent containers on different worktrees don't race.

## Initial Setup

Build the per-agent base images (all tagged with today's date as `local/agent-<name>:YYYY-MM-DD`) and create the shared credential volumes:

```bash
./build.sh
```

This produces:

- `local/agent-base:YYYY-MM-DD` — shared OS tooling, no agent CLIs
- `local/agent-claude:YYYY-MM-DD` — Claude Code
- `local/agent-codex:YYYY-MM-DD` — Codex CLI
- `local/agent-junie:YYYY-MM-DD` — Junie

…and the external Docker volumes `agent-creds-claude` and `agent-creds-codex` (Junie auths via env vars instead of a volume — see "Persistent Auth").

## New Project Setup

Copy the template into your project root:

```bash
cp -r /path/to/agent-container/template/. your-project/ && chmod +x your-project/agent
```

Then edit `your-project/.agent/compose.yaml` to pin today's date in the `BASE_IMAGE` build args for each service, and add project-specific runtimes to `your-project/.agent/Dockerfile` if needed (the Dockerfile is shared across all per-agent services).

To let a coding agent configure the environment for you, use the included `template/.agent/AGENT.md` as your prompt. The agent will inspect the repository, determine required runtimes and tooling, and update the Dockerfile accordingly.

## Usage

```bash
./agent claude         # start Claude Code
./agent codex          # start Codex CLI
./agent junie          # start Junie
./agent shell          # open a plain shell on the base image (no agent CLI, no shared creds)
./agent claude bash    # open a shell inside the claude container (e.g. for debugging)
```

The first argument is the compose service to enter. Anything after it is passed to the container as the command (overriding the service's default CMD).

## Persistent Auth

Each agent has its own external Docker volume, shared across every project on this host:

| Agent  | External volume      | Mount point inside container                                                                 |
|--------|----------------------|----------------------------------------------------------------------------------------------|
| Claude | `agent-creds-claude` | `/home/agent/.claude-shared` (entrypoint symlinks `~/.claude.json` and `~/.claude/` into it) |
| Codex  | `agent-creds-codex`  | `/home/agent/.codex`                                                                         |

Log in once for each agent and the token is reused by every project that uses the template.

Junie authenticates via CLI flags. Its compose service forwards these host env vars (omits whichever you haven't set):

- `JUNIE_AUTH` → `--auth`
- `ANTHROPIC_API_KEY` → `--anthropic-api-key`
- `OPENAI_API_KEY` → `--openai-api-key`
- `GROK_API_KEY` → `--grok-api-key`
- `OPENROUTER_API_KEY` → `--openrouter-api-key`
- `GOOGLE_API_KEY` → `--google-api-key`

Export whichever provider key you use on the host before running `./agent junie`.

Everything outside the credential mounts lives in the container's image layer for that run — no shared bash history, no shared caches. Two `./agent claude` runs on different worktrees can run concurrently without racing on transient home state.

## Update Strategy

Rebuild all per-agent images with a new date tag by re-running `./build.sh`. Then update the `BASE_IMAGE` build args in each project's `.agent/compose.yaml` to the new date and rebuild the per-project images:

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

Then attach each agent service to the same network in `.agent/compose.yaml` (the `x-defaults` anchor is a convenient place to apply it once):

```yaml
x-defaults: &defaults
  # …existing keys…
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
