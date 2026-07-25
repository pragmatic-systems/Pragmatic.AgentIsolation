#!/bin/sh
# Fix bind-mount ownership before dropping privileges
chown -R appuser:appgroup /home/appuser/work
chown -R appuser:appgroup /home/appuser/.pi 2>/dev/null || true
exec runuser -u appuser -- "$@"
