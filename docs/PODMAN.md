# Podman Image Build Documentation

This guide explains how to build custom PostgreSQL 18 and pgAdmin4 container images using Podman (or Docker).

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_


## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Image Overview](#image-overview)
- [Building Images](#building-images)
- [Containerfiles](#containerfiles)
- [Customization](#customization)
- [Testing Images](#testing-images)
- [Pushing to Registry](#pushing-to-registry)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### Required Tools

- **Podman** (recommended) or Docker
  ```bash
  # Install on RHEL/Fedora
  sudo dnf install podman
  
  # Install on Ubuntu/Debian
  sudo apt install podman
  ```

- **Buildah** (optional, for advanced builds)
  ```bash
  sudo dnf install buildah
  ```

### Optional Tools

- **Skopeo** - For image inspection and copying
  ```bash
  sudo dnf install skopeo
  ```

## 📦 Image Overview

### PostgreSQL 18 Image

**Containerfile**: `Containerfile.postgresql`

**Key Features:**
- Base: Red Hat UBI9 Minimal
- PostgreSQL Version: 18.1
- User: postgres (UID 1001)
- Port: 5432
- Rootless: Yes
- Health Check: Included
- Init Scripts: Supported via `/docker-entrypoint-initdb.d/`

**Image Size**: ~250 MB

### pgAdmin4 Image

**Containerfile**: `Containerfile.pgadmin`

**Key Features:**
- Base: Red Hat UBI9 Minimal
- pgAdmin Version: 9.11
- User: pgadmin (UID 1001)
- Port: 8080 (non-privileged)
- Rootless: Yes
- Python: 3.11

**Image Size**: ~450 MB

## 🏗️ Building Images

### Quick Build (Using build.sh)

The provided `build.sh` script simplifies the build process:

```bash
cd podman/

# Build PostgreSQL image with defaults
./build.sh

# Build with custom registry
REGISTRY=registry.example.com ./build.sh

# Build with custom name and tag
IMAGE_NAME=postgres IMAGE_TAG=18.1 ./build.sh

# Build all-in-one with custom settings
REGISTRY=registry.example.com IMAGE_NAME=postgresql IMAGE_TAG=18 ./build.sh
```

### Manual Build - PostgreSQL

```bash
cd podman/

# Build the image
podman build -t postgresql:18 -f Containerfile.postgresql .

# Build and tag for your registry
podman build -t your-registry.example.com/postgresql:18 -f Containerfile.postgresql .

# Build with specific platform
podman build --platform linux/amd64 -t postgresql:18 -f Containerfile.postgresql .

# Build with no cache (clean build)
podman build --no-cache -t postgresql:18 -f Containerfile.postgresql .
```

### Manual Build - pgAdmin4

```bash
cd podman/

# Build the image
podman build -t pgadmin:latest -f Containerfile.pgadmin .

# Build and tag for your registry
podman build -t your-registry.example.com/pgadmin:latest -f Containerfile.pgadmin .
```

### Build Both Images

```bash
cd podman/

# PostgreSQL
podman build -t your-registry.example.com/postgresql:18 -f Containerfile.postgresql .

# pgAdmin
podman build -t your-registry.example.com/pgadmin:latest -f Containerfile.pgadmin .
```

## 📄 Containerfiles

### Containerfile.postgresql (PostgreSQL)

The PostgreSQL Containerfile performs the following steps:

1. **Base Image**: Uses Red Hat UBI9 Minimal
2. **Install PostgreSQL**: Installs PostgreSQL 18 from official RPM repositories
3. **Create User**: Creates non-root postgres user (UID 1001)
4. **Configure Permissions**: Sets proper file permissions
5. **Copy Scripts**: Includes custom entrypoint and initialization scripts
6. **Set Environment**: Configures PostgreSQL environment variables
7. **Health Check**: Adds pg_isready-based health check
8. **Expose Port**: Documents port 5432

**Key Environment Variables:**
```dockerfile
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=postgres
ENV PGDATA=/var/lib/postgresql/data
```

### Containerfile.pgadmin (pgAdmin4)

The pgAdmin Containerfile performs the following steps:

1. **Base Image**: Uses Red Hat UBI9 Minimal
2. **Install Python**: Installs Python 3.11 and pip
3. **Install pgAdmin**: Installs pgAdmin4 from PyPI
4. **Create User**: Creates non-root pgadmin user (UID 1001)
5. **Configure Directories**: Sets up config and storage directories
6. **Copy Entrypoint**: Includes custom entrypoint script
7. **Set Permissions**: Ensures proper file ownership
8. **Expose Port**: Uses port 8080 (non-privileged)

**Key Environment Variables:**
```dockerfile
ENV PGADMIN_DEFAULT_EMAIL=admin@example.com
ENV PGADMIN_LISTEN_ADDRESS=0.0.0.0
ENV PGADMIN_LISTEN_PORT=8080
```

## 🎨 Customization

### Database Initialization Scripts

Place SQL scripts in `docker-entrypoint-initdb.d/`:

```bash
# Example: Create initial database structure
cat > docker-entrypoint-initdb.d/01-init.sql <<'EOF'
-- Create database
CREATE DATABASE myapp;

-- Create user
CREATE USER appuser WITH ENCRYPTED PASSWORD 'CHANGE_ME';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO appuser;

-- Create schema
\c myapp
CREATE SCHEMA app_schema;
GRANT ALL ON SCHEMA app_schema TO appuser;
EOF
```

These scripts run automatically on first container start.

### Custom PostgreSQL Configuration

Modify `postgresql-entrypoint.sh` or add custom config:

```bash
# Add to Containerfile
COPY custom-postgresql.conf /etc/postgresql/

# Add to entrypoint
echo "include = '/etc/postgresql/custom-postgresql.conf'" >> $PGDATA/postgresql.conf
```

### Change PostgreSQL Version

Edit the Containerfile.postgresql:

```dockerfile
# Change PostgreSQL version
RUN dnf install -y \
    https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf install -y postgresql16-server postgresql16-contrib && \
    dnf clean all
```

### Change pgAdmin Version

Edit Containerfile.pgadmin:

```dockerfile
# Install specific pgAdmin version
RUN pip3 install --no-cache-dir pgadmin4==9.10
```

### Add Extensions

To include PostgreSQL extensions:

```dockerfile
# Add to Containerfile.postgresql
RUN dnf install -y \
    postgresql18-contrib \
    postgresql18-devel \
    postgis34_18 \
    && dnf clean all
```

## 🧪 Testing Images

### Test PostgreSQL Image Locally

```bash
# Run the container
podman run -d \
  --name postgres-test \
  -e POSTGRES_PASSWORD=testpass \
  -p 5432:5432 \
  postgresql:18

# Check if it's running
podman ps

# View logs
podman logs postgres-test

# Test connection
podman exec -it postgres-test psql -U postgres -c "SELECT version();"

# Test health check
podman healthcheck run postgres-test

# Cleanup
podman stop postgres-test
podman rm postgres-test
```

### Test pgAdmin Image Locally

```bash
# Run the container
podman run -d \
  --name pgadmin-test \
  -e PGADMIN_DEFAULT_EMAIL=admin@test.com \
  -e PGADMIN_DEFAULT_PASSWORD=testpass \
  -p 8080:8080 \
  pgadmin:latest

# Check if it's running
podman ps

# View logs
podman logs pgadmin-test

# Test in browser
# Open: http://localhost:8080

# Cleanup
podman stop pgadmin-test
podman rm pgadmin-test
```

### Test Both Together

```bash
# Create a pod
podman pod create --name postgres-pod -p 5432:5432 -p 8080:8080

# Run PostgreSQL
podman run -d \
  --pod postgres-pod \
  --name postgres \
  -e POSTGRES_PASSWORD=testpass \
  postgresql:18

# Run pgAdmin
podman run -d \
  --pod postgres-pod \
  --name pgadmin \
  -e PGADMIN_DEFAULT_EMAIL=admin@test.com \
  -e PGADMIN_DEFAULT_PASSWORD=testpass \
  pgadmin:latest

# Test connection
# pgAdmin: http://localhost:8080
# Add server in pgAdmin:
#   Host: localhost
#   Port: 5432
#   User: postgres
#   Password: testpass

# Cleanup
podman pod stop postgres-pod
podman pod rm postgres-pod
```

## 📤 Pushing to Registry

### Docker Hub

```bash
# Login
podman login docker.io

# Tag images
podman tag postgresql:18 docker.io/yourusername/postgresql:18
podman tag pgadmin:latest docker.io/yourusername/pgadmin:latest

# Push
podman push docker.io/yourusername/postgresql:18
podman push docker.io/yourusername/pgadmin:latest
```

### Private Registry

```bash
# Login to private registry
podman login registry.example.com

# Tag images
podman tag postgresql:18 registry.example.com/postgresql:18
podman tag pgadmin:latest registry.example.com/pgadmin:latest

# Push
podman push registry.example.com/postgresql:18
podman push registry.example.com/pgadmin:latest
```

### Quay.io

```bash
# Login
podman login quay.io

# Tag images
podman tag postgresql:18 quay.io/yourusername/postgresql:18
podman tag pgadmin:latest quay.io/yourusername/pgadmin:latest

# Push
podman push quay.io/yourusername/postgresql:18
podman push quay.io/yourusername/pgadmin:latest
```

### OpenShift Registry

```bash
# Login to OpenShift
oc login

# Create project
oc new-project database-images

# Get registry URL
REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

# Login to registry
podman login -u $(oc whoami) -p $(oc whoami -t) $REGISTRY

# Tag images
podman tag postgresql:18 $REGISTRY/database-images/postgresql:18
podman tag pgadmin:latest $REGISTRY/database-images/pgadmin:latest

# Push
podman push $REGISTRY/database-images/postgresql:18
podman push $REGISTRY/database-images/pgadmin:latest
```

## 🔍 Image Inspection

### View Image Details

```bash
# Inspect image
podman inspect postgresql:18

# View image layers
podman history postgresql:18

# View image size
podman images postgresql:18

# Check image labels
podman inspect --format='{{json .Config.Labels}}' postgresql:18 | jq
```

### Scan for Vulnerabilities

```bash
# Using Podman
podman scan postgresql:18

# Using Trivy
trivy image postgresql:18

# Using Grype
grype postgresql:18
```

### Export/Import Images

```bash
# Save image to tar
podman save -o postgresql-18.tar postgresql:18

# Load image from tar
podman load -i postgresql-18.tar

# Copy image to another registry (using skopeo)
skopeo copy \
  containers-storage:postgresql:18 \
  docker://registry.example.com/postgresql:18
```

## 🐛 Troubleshooting

### Build Fails with Network Error

```bash
# Use proxy if behind firewall
podman build --build-arg HTTP_PROXY=http://proxy:8080 \
  --build-arg HTTPS_PROXY=http://proxy:8080 \
  -t postgresql:18 -f Containerfile.postgresql .
```

### Permission Denied Errors

```bash
# Check SELinux context
ls -lZ podman/

# Fix SELinux context
chcon -Rt svirt_sandbox_file_t podman/

# Or disable SELinux enforcement (not recommended for production)
sudo setenforce 0
```

### Image Too Large

```bash
# Use multi-stage builds
# Clean up package cache
RUN dnf clean all && rm -rf /var/cache/dnf

# Use minimal base image
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Remove unnecessary packages
RUN microdnf remove <package-name>
```

### Build Cache Issues

```bash
# Clear build cache
podman system prune -a

# Build without cache
podman build --no-cache -t postgresql:18 -f Containerfile.postgresql .
```

### Registry Authentication Issues

```bash
# Check auth file location
echo $REGISTRY_AUTH_FILE

# Login with credentials file
podman login --authfile ~/auth.json registry.example.com

# Use credentials in build
podman build --authfile ~/auth.json -t postgresql:18 .
```

### PostgreSQL Won't Start

Check logs for common issues:

```bash
podman logs postgres-test

# Common issues:
# 1. Data directory permissions
# 2. Port already in use
# 3. Insufficient memory
# 4. Missing password environment variable
```

### pgAdmin Won't Start

```bash
podman logs pgadmin-test

# Common issues:
# 1. Missing required environment variables (email/password)
# 2. Port 8080 already in use
# 3. Python dependency issues
# 4. Permission issues with config directory
```

## 📊 Best Practices

### Security

- ✅ Always run as non-root user (UID 1001)
- ✅ Use specific image tags, not `latest`
- ✅ Scan images for vulnerabilities regularly
- ✅ Keep base images updated
- ✅ Use minimal base images (UBI Minimal)
- ✅ Don't include secrets in images
- ✅ Use multi-stage builds when possible

### Performance

- ✅ Minimize layers (combine RUN commands)
- ✅ Clean up package caches
- ✅ Use .containerignore file
- ✅ Order layers by frequency of change
- ✅ Use build cache effectively

### Maintenance

- ✅ Version your images (semantic versioning)
- ✅ Tag images with build date
- ✅ Document all customizations
- ✅ Keep Containerfiles in version control
- ✅ Automate builds with CI/CD
- ✅ Test images before deployment

## 🔄 Automated Builds

### Using GitHub Actions

```yaml
name: Build Container Images

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Podman
        run: |
          sudo apt-get update
          sudo apt-get -y install podman
      
      - name: Build PostgreSQL Image
        run: |
          cd podman
          podman build -t postgresql:18 -f Containerfile.postgresql .
      
      - name: Build pgAdmin Image
        run: |
          cd podman
          podman build -t pgadmin:latest -f Containerfile.pgadmin .
      
      - name: Test Images
        run: |
          podman run -d --name postgres -e POSTGRES_PASSWORD=test postgresql:18
          sleep 10
          podman exec postgres psql -U postgres -c "SELECT 1"
          podman stop postgres
```

### Using GitLab CI

```yaml
build:
  image: quay.io/podman/stable
  script:
    - cd podman
    - podman build -t postgresql:18 -f Containerfile.postgresql .
    - podman build -t pgadmin:latest -f Containerfile.pgadmin .
    - podman push $CI_REGISTRY_IMAGE/postgresql:18
    - podman push $CI_REGISTRY_IMAGE/pgadmin:latest
```

## 🔗 Additional Resources

- [Podman Documentation](https://docs.podman.io/)
- [Buildah Documentation](https://buildah.io/)
- [PostgreSQL Container Images](https://hub.docker.com/_/postgres)
- [Red Hat UBI Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/building_running_and_managing_containers/)
- [Container Best Practices](https://docs.projectatomic.io/container-best-practices/)

## 📝 Example: Complete Build and Deploy Workflow

```bash
# 1. Build images
cd /path/to/postgress/podman/
podman build -t registry.example.com/postgresql:18 -f Containerfile.postgresql .
podman build -t registry.example.com/pgadmin:latest -f Containerfile.pgadmin .

# 2. Test locally
podman run -d --name postgres-test -e POSTGRES_PASSWORD=test -p 5432:5432 registry.example.com/postgresql:18
podman exec postgres-test psql -U postgres -c "SELECT version();"
podman stop postgres-test && podman rm postgres-test

# 3. Push to registry
podman login registry.example.com
podman push registry.example.com/postgresql:18
podman push registry.example.com/pgadmin:latest

# 4. Deploy to Kubernetes
cd ../kubernetes/
kubectl apply -f .

# 5. Verify deployment
kubectl get pods -n database
kubectl logs -f postgresql-0 -n database -c postgresql
```
