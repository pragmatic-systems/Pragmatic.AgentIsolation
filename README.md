# Pi Agent Isolation Harness

A secure Docker container running the [Pi Coding Agent](https://pi.dev/) in isolation, with controlled filesystem access and LM Studio integration.

## Quick Start

### 1. Start the container in the background

```bash
docker compose up -d
```

### 2. Attach to Pi's interactive console

```bash
docker attach pi-coding-harness
```

## Prerequisites

- **Docker Desktop** running
- **LM Studio** running with the Local Server API enabled on port `1234`
- Your project source code in `./src/` (optional, mounted read-only)

## Architecture

```
Host Machine
├── ./src/          ← Your codebase (mounted read-only)
├── ./work/         ← Pi's read-write workspace
├── docker-compose.yml
├── Dockerfile
└── Container: pi-coding-harness
    ├── Runs Pi (Node.js 22)
    ├── Connects to LM Studio via host.docker.internal:1234
    ├── Non-root user, no capabilities, no privilege escalation
    └── Only reads/writes to ./work
```

## Security

| Control | Status | Details |
|---|---|---|
| Non-root user | ✅ | Runs as `appuser` |
| No privileged mode | ✅ | Default |
| Capabilities dropped | ✅ | `cap_drop: ALL` |
| No new privileges | ✅ | `no-new-privileges:true` |
| No port exposure | ✅ | No `ports:` block |
| Limited volume mounts | ✅ | Only `./work` (rw), `./src` (ro) |
| Resource limits | ✅ | 4GB RAM, 2 CPUs |

## Configuration

- **LM Studio API URL** is set via the `LMSTUDIO_API_URL` environment variable in `docker-compose.yml`
- **Custom models/providers** are configured in `models.json`
- **Pi cache** is persisted in a Docker volume (`pi_cache`) so it survives restarts

### Updating `models.json`

`models.json` is bind-mounted directly from the host, so changes take effect on the **next container start** — no rebuild needed:

```bash
docker compose up -d
docker attach pi-coding-harness
```

If you need to rebuild the image (e.g., after changing the Dockerfile):

```bash
docker compose build && docker compose up -d && docker attach pi-coding-harness
```
