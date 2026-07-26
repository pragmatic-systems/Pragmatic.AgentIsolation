# Pi Agent Isolation Harness — PowerShell
# Run from any directory; mounts CWD as Pi's workspace.

# Script runs from /scripts folder inside the Pragmatic.AgentIsolation repo. 
# Dockerfile/compose in parent directory.
$RepoRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path

# Build image (no-op if already built)
docker build -t pi-agent-isolation-host "$RepoRoot"

# Run Pi
docker run --rm `
  --name pi-agent-isolation-host `
  -v "${PWD}:/home/appuser/mount:rw" `
  -v pi_cache:/home/appuser/.pi/cache:rw `
  -v "//var/run/docker.sock:/var/run/docker.sock:rw" `
  -e HOME=/home/appuser `
  -e NODE_ENV=development `
  -e LMSTUDIO_API_URL=http://host.docker.internal:1234/v1 `
  --memory=4g --cpus=2.0 `
  -it pi-agent-isolation-host:latest
