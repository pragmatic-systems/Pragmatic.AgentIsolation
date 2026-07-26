#!/usr/bin/env bash
# Pi Agent Isolation Harness — Bash
# Run from any directory; mounts CWD as Pi's workspace.

set -euo pipefail

# Resolve repo root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Disable MSYS path conversion so Docker receives raw Unix paths
# (Git Bash auto-converts /... paths to C:/... which breaks WSL Docker daemons)
export MSYS_NO_PATHCONV=1

# Build image (no-op if already built)
docker build -q -t pi-agent-isolation-host "$REPO_ROOT" 2>/dev/null

# Run Pi
LAUNCH_DIR="$(basename "$(pwd)")"
docker run --rm \
  -w "/home/appuser/mount/${LAUNCH_DIR}" \
  -v "$(pwd):/home/appuser/mount/${LAUNCH_DIR}:rw" \
  -v pi_cache:/home/appuser/.pi/cache:rw \
  -v "/var/run/docker.sock:/var/run/docker.sock:rw" \
  -e HOME=/home/appuser \
  -e NODE_ENV=development \
  -e LMSTUDIO_API_URL=http://host.docker.internal:1234/v1 \
  --memory=4g --cpus=2.0 \
  -it pi-agent-isolation-host:latest
