# Pi Agent Isolation Harness — PowerShell
# Run from any directory; mounts CWD as Pi's workspace.
#
# Usage:
#   pi-agent-isolation-host             # locked-down (no Docker)
#   pi-agent-isolation-host --docker    # with Docker-in-Docker support (host socket)

# Script runs from /scripts folder inside the Pragmatic.AgentIsolation repo.
# Dockerfile/compose in parent directory.
$RepoRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path

# Parse arguments
$EnableDocker = $false
if ($args -contains "--docker") {
    $EnableDocker = $true
}

# Select Dockerfile and image name
if ($EnableDocker) {
    $Dockerfile = "Dockerfile"
    $ImageName = "pi-agent-isolation-host-dind"
    Write-Host "[pi-agent] Docker-in-Docker enabled (host socket)"
} else {
    $Dockerfile = "Dockerfile.locked"
    $ImageName = "pi-agent-isolation-host"
    Write-Host "[pi-agent] Locked-down mode (no Docker)"
}

# Build image (no-op if already built)
docker build -f "$RepoRoot/$Dockerfile" -t $ImageName "$RepoRoot"

# Run Pi
$LaunchDir = Split-Path $PWD -Leaf

# Build common arguments
$DockerArgs = @(
    "--rm",
    "-w", "/home/appuser/mount/${LaunchDir}",
    "-v", "${PWD}:/home/appuser/mount/${LaunchDir}:rw",
    "-v", "pi_cache:/home/appuser/.pi/cache:rw",
    "-e", "HOME=/home/appuser",
    "-e", "NODE_ENV=development",
    "-e", "LMSTUDIO_API_URL=http://host.docker.internal:1234/v1",
    "--memory=8g",
    "--cpus=4.0",
    "-it"
)

if (-not $EnableDocker) {
    # Apply security restrictions for locked-down mode
    $DockerArgs += "--cap-drop=ALL"
    $DockerArgs += "--security-opt=no-new-privileges:true"
} else {
    # Mount Docker socket for DinD support
    $DockerArgs += "-v"
    $DockerArgs += "//var/run/docker.sock:/var/run/docker.sock:rw"
}

$DockerArgs += $ImageName

docker run $DockerArgs
