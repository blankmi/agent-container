# Agent Instructions

Your task is to prepare and maintain the project-specific agent container environment.

## Goals

- Ensure the repository can be built, tested and executed inside the container
- Keep the environment reproducible
- Keep the container minimal
- Prefer deterministic tooling and versions
- Avoid unnecessary global tooling

---

# Responsibilities

## Analyze the Repository

Inspect the repository structure and automatically determine:

- required programming languages
- required runtimes
- required package managers
- required build tools
- required test tools
- required external services
- required CLIs/utilities

Examples:

- Java
- Maven
- Gradle
- Node.js
- pnpm
- Go
- Python
- Playwright
- PostgreSQL client
- Redis tools

Use repository files to infer requirements.

Examples:

- `pom.xml`
- `build.gradle`
- `package.json`
- `pnpm-lock.yaml`
- `.nvmrc`
- `Dockerfile`
- `docker-compose.yml`
- `.tool-versions`
- CI configuration

If none of these files are present, inspect source file extensions and directory structure to infer the language and toolchain. If requirements cannot be determined, ask before proceeding.

---

# Container Setup

Update `.agent/Dockerfile` when additional tooling is required.

Requirements:

- prefer official package repositories
- prefer stable LTS versions
- keep image size minimal — remove build tools not needed at runtime
- avoid duplicate tooling
- remove unnecessary packages
- keep layers clean

Do not install tools that are not required by the repository.

---

# Networking

Inspect existing Docker Compose files and infrastructure configuration.

If the repository depends on external containers/services:

- ensure the agent container joins the correct Docker network
- prefer existing external networks
- do not expose unnecessary ports

Services inside Docker networks should be accessed via service/container name.

Do not use `localhost` for container-to-container communication.

Use `host.docker.internal` only for services running directly on the macOS host.

---

# Validation

After updating the environment:

1. build the project
2. execute tests
3. verify formatting/linting if configured
4. verify installed CLIs respond correctly (e.g. `node --version`, `mvn --version`)

The environment is considered valid only if the repository builds and tests successfully. If validation fails, diagnose the root cause, fix the Dockerfile or compose.yaml, and re-validate. Do not mark the environment valid until all steps pass.

---

# Security

- prefer least privilege
- do not mount unnecessary host directories
- do not persist secrets inside images
- pass build-time secrets via `docker build --secret` or mounted files, never as `ENV` or `ARG` values baked into the image
- use mounted Docker volumes for agent sessions/authentication
- avoid privileged containers
- avoid adding unnecessary Linux capabilities

---

# Persistence

Agent authentication and sessions are persisted via mounted Docker volumes.

Do not modify this behavior.

Expected persistent directories:

- `/home/agent/.claude`
- `/home/agent/.codex`
- `/home/agent/.junie`

---

# Workflow

When environment changes are required:

1. explain why the change is necessary
2. update `.agent/Dockerfile`
3. update `.agent/compose.yaml` if required
4. rebuild the container: `docker compose -f .agent/compose.yaml build`
5. validate the setup

You are expected to run these commands yourself. Do not ask the user to build or start the container.

Prefer minimal, incremental changes.

---

# General Rules

- prefer reproducibility over convenience
- prefer explicit configuration over implicit assumptions
- prefer repository-local tooling
- avoid modifying unrelated infrastructure
- avoid introducing unnecessary services
- keep startup time reasonable
- keep resource usage reasonable
