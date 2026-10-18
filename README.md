# 1. Implementation of Dockerfile

```dockerfile
# Multi-stage not required due to zero build dependencies; using hardened single-stage Alpine
FROM python:3.12-alpine

# Create unprivileged system group and user (explicit UID/GID for Kubernetes RunAsUser compatibility)
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

WORKDIR /app

# Copy application source code and set ownership
COPY --chown=10001:10001 app/ /app/

# Expose service port
EXPOSE 8080

# Switch to non-root execution
USER 10001:10001

ENTRYPOINT ["python", "app.py"]
```

### A. Minimal Footprint (~50 MB)
  - We used the Base Image as python:3.12-alpine, a stripped-down Alpine Linux base rather than standard Debian/Ubuntu (~1 GB), dramatically reducing pull times and vulnerability surface.

  - We used Single-Layer Chown: COPY --chown=... directly. This avoids duplicate disk layers caused by copying as root and running RUN chown afterward.


### B. Security Hardening
#### We used Least Privilege Non-Root Execution:

```dockerfile
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

WORKDIR /app

COPY --chown=10001:10001 app/ /app/
```

  - It Avoids default root access. </br>

  - Creates an unprivileged system user/group (appuser / appgroup). </br>

  - Enforces fixed numeric IDs (10001:10001), ensuring compatibility with Kubernetes security contexts (runAsNonRoot: true, runAsUser: 10001). </br>

  - Reduced Attack Surface: The Alpine base excludes extraneous utilities and shells often targeted for living-off-the-land attacks.

### Docker image building

```sh
docker build -t my-python-app:latest .
[+] Building 0.2s (9/9) FINISHED                                                            docker:default
 => [internal] load build definition from Dockerfile                                                  0.0s
 => => transferring dockerfile: 554B                                                                  0.0s
 => [internal] load metadata for docker.io/library/python:3.12-alpine                                 1.0s
 => [internal] load .dockerignore                                                                     0.0s
 => => transferring context: 152B                                                                     0.0s
 => CACHED [1/4] FROM docker.io/library/python:3.12-alpine@sha256:1b668429b3511ab407d8e00648891631b0  0.0s
 => [internal] load build context                                                                     0.0s
 => => transferring context: 55B                                                                      0.0s
 => [2/4] RUN addgroup -g 10001 -S appgroup && adduser -u 10001 -S appuser -G appgroup                0.0s
 => [3/4] WORKDIR /app                                                                                0.0s
 => [4/4] COPY --chown=10001:10001 app/ /app/                                                         0.0s
 => exporting to image                                                                                0.1s
 => => exporting layers                                                                               0.1s
 => => writing image sha256:3d3bc1dcccd520ac7a3b193ed60ee90ffa89d1394479fd0dba69ca798d736375          0.0s
 => => naming to docker.io/library/my-python-app:latest


docker run -d   --name my-python-app   -p 8081:8080   --read-only   --tmpfs /tmp   my-python-app:latest
bcd98a707f97ab5272240b65ad56d4e92bf35ebdffe0be84cf7b6bba386b8c1c

docker ps
CONTAINER ID   IMAGE                  COMMAND           CREATED          STATUS          PORTS                                         NAMES
bcd98a707f97   my-python-app:latest   "python app.py"   36 seconds ago   Up 36 seconds   0.0.0.0:8081->8080/tcp, [::]:8081->8080/tcp   my-python-app

curl http://127.0.0.1:8081/healthcheck
{"status": "healthy"}

```

---
---














