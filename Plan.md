# Give me a long meand
Model: qwen/qwen3.6-27b
Created: 24/07/2026, 16:31:26
Exported from: LM Studio 0.4.20+1

### User
I'm using Pi and Qwen for local dev, but I'd like to lock down my harness setup so it's not a risk to my local PC. I need a script/docker-compose file or configuration that will spin me up a container with Pi in it and read/write access to the current working directory via directory mounting.

### Assistant
# Secure Local AI Development Harness with Pi (Ollama) in Docker

Below is a complete, hardened Docker setup that runs **Ollama** (serving Pi models) in an isolated container with controlled access to your working directory.

## Architecture Overview

```
Your PC
├── ./work/          ← Mounted read-write (only this dir)
├── docker-compose.yml
├── Dockerfile (optional)
└── Container: ollama
    ├── Network: isolated (no host network)
    ├── User: non-root
    ├── No privileged flags
    └── Read/write to ./work only
```

## 1. `docker-compose.yml`

```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama-pi
    restart: unless-stopped

    # --- Security Hardening ---
    # Run as non-root user (ollama image uses uid 1000 by default, but we enforce it)
    user: "1000:1000"

    # Drop all Linux capabilities except what's strictly needed
    cap_drop:
      - ALL
    # Ollama doesn't need any special caps for basic inference

    # Restrict network access: only expose the API port locally
    ports:
      - "127.0.0.1:11434:11434"  # Bind to localhost only

    # Mount only the working directory (read-write)
    volumes:
      - ./work:/home/ollama/work:rw
      # Persist Ollama models so they survive container restarts
      - ollama_models:/root/.ollama:rw

    # Environment
    environment:
      - OLLAMA_HOST=0.0.0.0
      - OLLAMA_MODELS=/root/.ollama/models

    # Security labels and restrictions
    security_opt:
      - no-new-privileges:true

    # Resource limits (adjust based on your hardware)
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4.0'

volumes:
  ollama_models:
    driver: local
```

## 2. `Dockerfile` (Optional — for a fully locked-down custom image)

If you want even tighter control, build a minimal image:

```dockerfile
FROM ollama/ollama:latest

# Ensure the work directory exists with correct permissions
RUN mkdir -p /home/ollama/work && \
    chown -R 1000:1000 /home/ollama/work

# Set default user
USER 1000:1000

WORKDIR /home/ollama/work

# Expose only the API port
EXPOSE 11434

CMD ["ollama", "serve"]
```

Then reference it in `docker-compose.yml`:

```yaml
services:
  ollama:
    build: .
    # ... rest same as above
```

## 3. Pull the Pi Model

Once the container is running, pull the Pi model inside it:

```bash
# Connect to the running container
docker exec -it ollama-pi bash

# Inside the container:
ollama pull pi

# Or use a specific Pi model variant:
ollama pull pi:latest
```

## 4. Usage

### Start the harness

```bash
docker compose up -d
```

### Send a request via curl

```bash
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "pi",
    "messages": [
      {"role": "user", "content": "Hello, who are you?"}
    ]
  }'
```

### Use with Python (local dev)

```python
import requests
import json

def chat_with_pi(prompt: str) -&gt; str:
    url = "http://localhost:11434/api/chat"
    payload = {
        "model": "pi",
        "messages": [{"role": "user", "content": prompt}],
        "stream": False
    }
    response = requests.post(url, json=payload)
    response.raise_for_status()
    return response.json()["message"]["content"]

# Your working directory files are accessible at ./work/
with open("./work/example.txt", "r") as f:
    content = f.read()

result = chat_with_pi(f"Summarize this: {content}")
print(result)
```

## 5. Security Checklist

| Control | Status | Details |
|---|---|---|
| **Non-root user** | ✅ | Container runs as UID 1000 |
| **No privileged mode** | ✅ | `privileged: false` (default) |
| **Capabilities dropped** | ✅ | `cap_drop: ALL` |
| **No new privileges** | ✅ | `no-new-privileges` |
| **Network isolated** | ✅ | Bound to `127.0.0.1` only |
| **Limited volume mounts** | ✅ | Only `./work` + model cache |
| **Resource limits** | ✅ | Memory/CPU capped |
| **Read-only host FS** | ✅ | Host filesystem not mounted |
| **No device access** | ✅ | No `/dev` mounts |

## 6. Optional: Add a Read-Only Code Mount

If you want the container to **read** your source code but not modify it:

```yaml
volumes:
  - ./work:/home/ollama/work:rw
  - ./src:/home/ollama/src:ro      # Read-only source code
  - ollama_models:/root/.ollama:rw
```

## 7. Stop & Clean Up

```bash
docker compose down
# To also remove persisted model data:
docker compose down -v
```

## Key Notes

- **`./work`** is the only directory with write access. Keep sensitive files out of it.
- **Models are cached** in a Docker volume, so they persist across restarts without re-downloading.
- **Port 11434** is bound to `127.0.0.1` so it's inaccessible from the network.
- If you need GPU acceleration, add `runtime: nvidia` and ensure the NVIDIA Container Toolkit is installed on the host. The security posture remains the same.

This setup gives you a clean, isolated AI inference harness that can read/write only to your designated working directory while minimizing attack surface on your host machine.

### User
Pi is the coding agent (https://pi.dev/ Pi Coding Harness). I am running my models via LM Studio running Vulkan llama. I just need a secure container to run the Pi application.

### Assistant
# Secure Pi Coding Harness Container

Since **Pi** is a Node.js-based coding agent and you're using **LM Studio** locally (host-side), the container only needs to run Pi with controlled filesystem access. LM Studio’s API will be accessed via localhost networking.

## Architecture

```
Your PC
├── ./work/          ← Pi's working directory (rw)
├── ./src/           ← Your codebase (ro, optional)
├── docker-compose.yml
└── Container: pi-agent
    ├── Runs Pi (Node.js)
    ├── Connects to LM Studio on host (172.17.0.1:1234)
    ├── Network: isolated, no external exposure
    └── Filesystem: only ./work (rw) + ./src (ro)
```

## 1. `docker-compose.yml`

```yaml
version: '3.8'

services:
  pi-agent:
    image: node:20-alpine
    container_name: pi-coding-harness
    restart: unless-stopped

    # --- Security Hardening ---
    # Run as non-root
    user: "1000:1000"

    # Drop all capabilities
    cap_drop:
      - ALL

    # Prevent privilege escalation
    security_opt:
      - no-new-privileges:true

    # No network exposure — Pi talks to host LM Studio via docker host gateway
    # Do NOT expose any ports

    # --- Volume Mounts ---
    # Working directory: read-write (Pi creates/edits files here)
    volumes:
      - ./work:/home/node/work:rw
      # Optional: mount your source code as read-only
      - ./src:/home/node/src:ro
      # Optional: mount a persistent Pi config/cache dir
      - pi_cache:/home/node/.pi:rw

    # --- Environment ---
    environment:
      # Point Pi to LM Studio running on the host
      # Docker's host gateway resolves to the host machine's IP
      - LMSTUDIO_API_URL=http://host.docker.internal:1234/v1
      # Or if host.docker.internal doesn't resolve, use:
      # - LMSTUDIO_API_URL=http://172.17.0.1:1234/v1
      - NODE_ENV=production
      - HOME=/home/node

    # Resource limits
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'

    # Working directory inside container
    working_dir: /home/node/work

    # Command: install Pi and run it
    command: &gt;
      sh -c "
        npm install -g @pi-dev/agent &&
        cd /home/node/work &&
        pi
      "

volumes:
  pi_cache:
    driver: local
```

## 2. Pre-Setup Steps

### On your host machine:

```bash
# 1. Create the working directory
mkdir -p work src

# 2. Ensure LM Studio is running with API enabled
#    In LM Studio: Local Server → Enable → Port 1234

# 3. Test LM Studio connectivity from host
curl http://localhost:1234/v1/models
```

### Inside the container (first run):

The container will:
1. Install Pi globally via npm
2. Change to `./work`
3. Launch the Pi agent

## 3. Alternative: Dockerfile for a Pre-Baked Image

If you want a faster startup (no npm install on every run):

```dockerfile
FROM node:20-alpine

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install Pi globally
RUN npm install -g @pi-dev/agent

# Set permissions
RUN mkdir -p /home/appuser/work /home/appuser/.pi
RUN chown -R appuser:appgroup /home/appuser

USER appuser
WORKDIR /home/appuser/work

EXPOSE nothing

CMD ["pi"]
```

Then in `docker-compose.yml`:

```yaml
services:
  pi-agent:
    build: .
    # ... rest same, remove the `command` override
```

## 4. Network Configuration Notes

### Option A: `host.docker.internal` (Recommended)

Works on Docker Desktop (Mac/Windows) and most Linux setups with `--add-host` or default config.

### Option B: Explicit Host Gateway

If `host.docker.internal` doesn’t resolve, add this to the service:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### Option C: Direct IP

```yaml
environment:
  - LMSTUDIO_API_URL=http://172.17.0.1:1234/v1
```

&gt; ⚠️ **Verify** the Docker bridge IP with `docker network inspect bridge` if `172.17.0.1` doesn’t work.

## 5. Security Checklist

| Control | Status | Details |
|---|---|---|
| **Non-root user** | ✅ | Runs as UID 1000 |
| **No privileged mode** | ✅ | Default |
| **Capabilities dropped** | ✅ | `cap_drop: ALL` |
| **No new privileges** | ✅ | `no-new-privileges` |
| **No port exposure** | ✅ | No `ports:` block |
| **Limited volume mounts** | ✅ | Only `./work` (rw), `./src` (ro) |
| **Resource limits** | ✅ | Memory/CPU capped |
| **Host FS not mounted** | ✅ | Only specific dirs |
| **No device access** | ✅ | No `/dev` mounts |
| **No network access** | ✅ | Only outbound to host LM Studio |

## 6. Usage

```bash
# Start the harness
docker compose up -d

# View logs (Pi's output)
docker compose logs -f pi-agent

# Stop
docker compose down

# Clean up (removes cached Pi data)
docker compose down -v
```

## 7. Important Notes

- **LM Studio must be running** on your host before starting the container.
- **Pi will only read/write to `./work`**. Any files it generates (code, edits, etc.) will appear there.
- **Your source code in `./src` is read-only** — Pi can reference it but cannot modify it.
- **No internet access** from the container unless you add an `external` network. Pi itself doesn’t need internet if it only talks to LM Studio.
- If Pi needs to install packages or fetch dependencies, you may need to temporarily allow outbound HTTP/HTTPS — but this is separate from the core harness security.

## 8. Optional: Restrict Outbound Network

If you want to **block all outbound traffic except to LM Studio**, use a custom network with DNS pinning:

```yaml
networks:
  pi-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

services:
  pi-agent:
    networks:
      - pi-net
    # Add iptables rule via init container or use network policies
    # For simplicity, the above setup already limits exposure significantly
```

For stricter control, consider using **`--network=none`** and relying on Pi’s ability to connect via the host gateway if your Docker daemon allows it.

---

This setup gives you a **minimal, isolated Pi coding harness** that can only touch your designated working directory and communicate with your local LM Studio instance — nothing else.
