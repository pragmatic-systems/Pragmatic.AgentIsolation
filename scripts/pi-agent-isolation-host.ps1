# Pi Agent Isolation Harness — PowerShell
# Run from any directory; mounts CWD as Pi's workspace.

# Script runs from /scripts folder inside the Pragmatic.AgentIsolation repo. 
# Dockerfile/compose in parent directory.
$RepoRoot = Split-Path -Parent $PSScriptRoot

# Build image (no-op if already built)
docker compose -f "$RepoRoot\docker-compose.yml" build

# Run Pi
docker run --rm `
  --name pi-agent-isolation-host `
  -v "${PWD}:/home/appuser/mount:rw" `
  -v pi_cache:/home/appuser/.pi:rw `
  -v "${RepoRoot}\models.json:/home/appuser/.pi/agent/models.json:ro" `
  -e HOME=/home/appuser `
  -e NODE_ENV=development `
  -e LMSTUDIO_API_URL=http://host.docker.internal:1234/v1 `
  --cap-drop=ALL `
  --security-opt=no-new-privileges:true `
  --memory=4g --cpus=2.0 `
  -it pi-agent-isolation-host:latest
