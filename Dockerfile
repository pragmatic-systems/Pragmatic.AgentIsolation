# -----------------------------------------------------------
# Pi Coding Agent — isolated harness
# -----------------------------------------------------------
# Single-stage image: .NET SDK 10.0 + Node.js 22 + Pi
# -----------------------------------------------------------

FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine

# Install Node.js 22, Docker CLI, and Pi
RUN apk add --no-cache nodejs npm docker && \
    npm install -g @earendil-works/pi-coding-agent

# --- Non-root user ---
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# --- Directories ---
RUN mkdir -p /home/appuser/mount /home/appuser/.pi/agent && \
    chown -R appuser:appgroup /home/appuser

# --- Pi model config (baked in to avoid WSL path-mount issues) ---
COPY models.json /home/appuser/.pi/agent/models.json

USER appuser
WORKDIR /home/appuser/mount

ENV HOME=/home/appuser
ENV NODE_ENV=development

# Launch Pi TUI directly so docker attach works
CMD ["pi"]
