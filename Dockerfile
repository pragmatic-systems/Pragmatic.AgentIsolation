# -----------------------------------------------------------
# Pi Coding Agent — isolated harness
# -----------------------------------------------------------
# Build stage: install Pi globally, then bake into a minimal
# runtime image so no npm work happens at container start.
# -----------------------------------------------------------

FROM node:22-alpine AS builder

RUN npm install -g @earendil-works/pi-coding-agent

# -----------------------------------------------------------
# Runtime stage
# -----------------------------------------------------------
FROM node:22-alpine

# --- Non-root user ---
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only the global node_modules (Pi + deps) from builder
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

# --- Directories ---
RUN mkdir -p /home/appuser/work /home/appuser/.pi && \
    chown -R appuser:appgroup /home/appuser

USER appuser
WORKDIR /home/appuser/work

ENV HOME=/home/appuser
ENV NODE_ENV=development

# Default to a long-running shell so you can docker exec in and run `pi` interactively
CMD ["sh", "-c", "while true; do sleep 86400; done"]
