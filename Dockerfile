# -----------------------------------------------------------
# Pi Coding Agent — isolated harness
# -----------------------------------------------------------
# Build stage: install Pi globally on top of .NET SDK 10.0,
# then bake into a minimal runtime image so no npm work
# happens at container start.
# -----------------------------------------------------------

FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS builder

# Install Node.js 22 for Pi
RUN apk add --no-cache nodejs npm

RUN npm install -g @earendil-works/pi-coding-agent

# -----------------------------------------------------------
# Runtime stage
# -----------------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine

# Install Node.js 22 for Pi runtime
RUN apk add --no-cache nodejs npm

# --- Non-root user ---
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only the global node_modules (Pi + deps) from builder
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

# --- Directories ---
RUN mkdir -p /home/appuser/work /home/appuser/.pi/agent && \
    chown -R appuser:appgroup /home/appuser

USER appuser
WORKDIR /home/appuser/work

ENV HOME=/home/appuser
ENV NODE_ENV=development

# Launch Pi TUI directly so docker attach works
CMD ["pi"]
