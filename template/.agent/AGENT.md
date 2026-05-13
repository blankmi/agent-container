# Agent Instructions

Your task: extend `.agent/Dockerfile` with the runtimes and CLIs this repository needs, so it can be built, tested, and run inside the container. The README explains the per-agent image layout, the `./agent` launcher, and the persistent auth model — read it first if you haven't.

## Goals

- Install everything the repository requires to build, test, and run
- Install nothing it doesn't
- Keep the image reproducible — pinned, official, deterministic versions

## Analyze the Repository

Inspect the repo to determine required languages, runtimes, build tools, package managers, and CLIs.

Useful signals: `pom.xml`, `build.gradle`, `package.json`, `pnpm-lock.yaml`, `.nvmrc`, `Dockerfile`, `docker-compose.yml`, `.tool-versions`, `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, CI configs.

If none are present, infer from source file extensions and directory structure. If the requirements cannot be determined, ask before proceeding.

## Extending the Image

`.agent/Dockerfile` is a single project-specific Dockerfile, parameterised by `ARG BASE_IMAGE`. Each compose service (`claude`, `codex`, `junie`, `shell`) builds it on top of a different `local/agent-*` base. **Anything you add applies to every service** — there is no per-agent variant to maintain.

Add tooling between the existing `USER root` / `USER agent` lines.

Example (Java + Maven):

```dockerfile
USER root
RUN apt-get update && apt-get install -y openjdk-21-jdk maven \
 && rm -rf /var/lib/apt/lists/*
USER agent
```

Guidelines:

- Prefer official package repositories and pinned versions
- Clean up in the same RUN (e.g. `rm -rf /var/lib/apt/lists/*`)
- Do not install tools the repository doesn't actually use
- Do not bake secrets into the image — use `docker build --secret` or mounted files

`.agent/compose.yaml` should only be edited for base image version bumps (the `BASE_IMAGE: local/agent-*:YYYY-MM-DD` lines) or network attachment. Runtime tooling belongs in the Dockerfile.

## Workflow

1. State why the change is needed
2. Edit `.agent/Dockerfile`
3. Rebuild: `docker compose -f .agent/compose.yaml build`
4. Validate (see below)

## Validation

Verify inside the container using the `shell` service so no agent CLI interferes.

Example:

```bash
./agent shell mvn --version       # confirm the toolchain
./agent shell mvn -B verify       # build + test
```

The environment is valid only when the repository builds and tests pass. If either fails, diagnose the root cause and re-validate. Do not mark the setup ready until both succeed.
