# Multi-stage not required due to zero build dependencies; using hardened single-stage Alpine
FROM python:3.12-alpine

# Create unprivileged system group and user (explicit UID/GID for Kubernetes RunAsUser compatibility)
RUN addgroup -g 10001 -S appgroup && adduser -u 10001 -S appuser -G appgroup

WORKDIR /app

# Copy application source code and set ownership
COPY --chown=10001:10001 app/ /app/

# Expose service port
EXPOSE 8080

# Switch to non-root execution
USER 10001:10001

ENTRYPOINT ["python", "app.py"]
