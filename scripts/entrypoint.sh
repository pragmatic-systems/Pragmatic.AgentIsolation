#!/usr/bin/env bash
# Seed .pi/agent with baked-in config on first run, then launch Pi.
#
# The pi_agent volume is mounted over /home/appuser/.pi/agent, which shadows
# anything COPY'd there during the build. This entrypoint copies the baked-in
# files (stored under /opt/pi-agent/) into the live directory only if they
# don't already exist — so user changes are preserved across runs.

set -euo pipefail

AGENT_DIR="$HOME/.pi/agent"
SEED_DIR="/opt/pi-agent"

# Ensure the target directory exists (volume may be freshly created)
mkdir -p "$AGENT_DIR/extensions"

# Seed each baked-in file if not already present
for f in "$SEED_DIR"/*; do
  dest="$AGENT_DIR/$(basename "$f")"
  if [ ! -e "$dest" ]; then
    cp "$f" "$dest"
  fi
done

# Hand off to Pi
exec pi
