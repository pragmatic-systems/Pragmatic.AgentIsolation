# Pi Agent Isolation Harness

A secure Docker container running the [Pi Coding Agent](https://pi.dev/) in isolation, with controlled filesystem access and LM Studio integration.

## Setup

Add the `scripts/` folder to your `%PATH%` (Windows) or `$PATH` (Linux/macOS):

### Windows (PowerShell)
```powershell
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\path\to\Pragmatic.AgentIsolation\scripts", "User")
```

### Linux / macOS
```bash
export PATH="$PATH:/path/to/Pragmatic.AgentIsolation/scripts"
```

## Quick Start

Run `pi-agent-isolation-host` from any directory — it mounts your current working directory as Pi's workspace:

```bash
cd /path/to/your/project
pi-agent-isolation-host
```

When you exit Pi (Ctrl+C), the container is automatically cleaned up.

### Modes

| Mode | Command | Docker CLI | Socket Mount | Security Hardening |
|---|---|---|---|---|
| **Locked-down** (default) | `pi-agent-isolation-host` | ❌ | ❌ | `--cap-drop=ALL`, `no-new-privileges` |
| **Docker-in-Docker** | `pi-agent-isolation-host --docker` | ✅ | ✅ | Relaxed (for DinD compatibility) |

```bash
# With Docker support (opt-in)
pi-agent-isolation-host --docker
```

## Prerequisites

- **Docker Desktop** running
- **LM Studio** running with the Local Server API enabled on port `1234`

## Runtime Environment

The container ships with:

| Tool | Version |
|---|---|
| .NET SDK | 10.0.100, 9.0, 8.0 |
| Node.js | 22 (Alpine) |
| Docker CLI | Alpine edge (DinD mode only) |

The container has **outbound internet access** by default, so Pi can install tools (e.g. `dotnet tool install`, `npm install`) and restore packages (`dotnet restore`, `npm ci`) at runtime.

## Architecture

```
Host Machine
├── Your project directory
│   └── (mounted as /home/appuser/mount inside container)
└── Container: pi-agent-isolation-host
    ├── Runs Pi (Node.js 22) + .NET SDK 10.0
    ├── Connects to LM Studio via host.docker.internal:1234
    ├── Outbound internet access (package restore, tool install)
    ├── Non-root user, no capabilities, no privilege escalation
    └── Auto-cleaned on exit (--rm)
```

## Security

| Control | Locked-down | DinD (`--docker`) | Details |
|---|---|---|---|
| Non-root user | ✅ | ✅ | Runs as `appuser` |
| No privileged mode | ✅ | ✅ | Default |
| No port exposure | ✅ | ✅ | No `ports:` block |
| Resource limits | ✅ | ✅ | 4GB/2 CPUs (bash), 8GB/4 CPUs (pwsh) |
| `--cap-drop=ALL` | ✅ | ❌ | All Linux capabilities dropped |
| `no-new-privileges` | ✅ | ❌ | Prevents privilege escalation |
| Docker socket mount | ❌ | ⚠️ | `/var/run/docker.sock` mounted |

## Configuration

- **LM Studio API URL** is set via the `LMSTUDIO_API_URL` environment variable
- **Custom models/providers** are configured in `models.json`
- **Pi cache** is persisted in a Docker volume (`pi_cache`) so it survives restarts

### Updating `models.json`

`models.json` is bind-mounted directly from the repo root, so changes take effect on the **next run**:

```bash
pi-agent-isolation-host
```

If you need to rebuild the image (e.g., after changing the Dockerfile):

```bash
docker build -t pi-agent-isolation-host .
pi-agent-isolation-host
```

## Docker-in-Docker

By default, the container runs in **locked-down mode** — no Docker CLI is installed, no socket is mounted, and all Linux capabilities are dropped. To enable Docker-in-Docker support, pass `--docker`:

```bash
pi-agent-isolation-host --docker
```

This builds from the full `Dockerfile` (which includes the Docker CLI) and mounts the host Docker socket, allowing Pi to run Docker commands (e.g., `docker build`, `docker run`, `docker compose`) against the host Docker daemon.

> **Security note:** Mounting the Docker socket grants the container significant control over the host Docker environment. The `--cap-drop=ALL` and `--security-opt=no-new-privileges` restrictions are relaxed in this mode to support it. Only use `--docker` when Docker support is actually needed.
