# Helm Deployment Guide

This guide covers deploying PostgreSQL 18 and pgAdmin4 using Helm charts for templating and package management.

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_


## 📋 Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Chart Structure](#chart-structure)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Advanced Usage](#advanced-usage)
- [Chart Development](#chart-development)
- [Troubleshooting](#troubleshooting)

## 📖 Introduction

### What is Helm?

Helm is the package manager for Kubernetes. It allows you to:

- ✅ Define, install, and upgrade Kubernetes applications
- ✅ Template Kubernetes manifests with Go templates
- ✅ Manage releases and rollbacks
- ✅ Share charts via repositories
- ✅ Handle dependencies between charts
- ✅ Customize deployments with values files

### Why Use Helm?

**Advantages:**
- Powerful templating engine
- Version-controlled releases
- Easy rollbacks
- Values override system
- Chart repositories for sharing
- Large ecosystem of community charts

**Best For:**
- Complex applications with many variations
- Organizations wanting package management
- Teams needing easy upgrades/rollbacks
- When templating is beneficial
- Sharing reusable deployments

## 🔧 Prerequisites

### Install Helm

```bash
# Install Helm 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Or using package manager
# macOS
brew install helm

# Linux (snap)
sudo snap install helm --classic

# Verify installation
helm version
```

### Cluster Requirements

- Kubernetes cluster (1.24+)
- kubectl configured to access your cluster
- Sufficient resources (CPU: 2 cores, Memory: 4GB)
- PersistentVolume support
- Container images in a registry

### Optional Tools

```bash
# Helm diff plugin (recommended)
helm plugin install https://github.com/databus23/helm-diff

# Helm secrets plugin
helm plugin install https://github.com/jkroepke/helm-secrets
```

## 📁 Chart Structure

```
helm/postgresql-pgadmin/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── values-dev.yaml         # Development overrides
├── values-staging.yaml     # Staging overrides
├── values-production.yaml  # Production overrides
├── README.md              # Chart documentation
├── .helmignore            # Files to ignore
│
├── templates/             # Kubernetes manifests (templated)
│   ├── NOTES.txt          # Post-install instructions
│   ├── _helpers.tpl       # Template helpers
│   ├── namespace.yaml     # Namespace
│   ├── configmap.yaml     # ConfigMap
│   ├── secrets.yaml       # Secrets
│   ├── pvc.yaml           # Persistent Volume Claim
│   ├── statefulset.yaml   # StatefulSet
│   ├── service.yaml       # Services
│   ├── ingress.yaml       # Ingress
│   └── tests/             # Helm tests
│       └── test-connection.yaml
│
└── charts/                # Dependent charts (if any)
```

## 🚀 Quick Start

### 1. Navigate to Helm Directory

```bash
cd helm/
```

### 2. Review Default Values

```bash
# View default values
cat postgresql-pgadmin/values.yaml

# View chart information
helm show chart postgresql-pgadmin/

# View all chart info
helm show all postgresql-pgadmin/
```

### 3. Create Custom Values File

Create `my-values.yaml`:

```yaml
# Image configuration
postgresql:
  image:
    registry: your-registry.example.com
    repository: postgresql
    tag: "18"
    pullPolicy: IfNotPresent

pgadmin:
  image:
    registry: your-registry.example.com
    repository: pgadmin
    tag: latest
    pullPolicy: IfNotPresent

# Image pull secret (if using private registry)
imagePullSecrets:
  - name: registry-secret

# PostgreSQL configuration
config:
  postgresDatabase: postgres
  postgresUser: postgres
  postgresPassword: "CHANGE_ME"  # Use --set or secrets file

# pgAdmin configuration
pgadminConfig:
  email: admin@example.com
  password: "CHANGE_ME"  # Use --set or secrets file

# Storage
persistence:
  enabled: true
  storageClass: "standard"  # Your storage class
  size: 10Gi

# Ingress
ingress:
  enabled: true
  className: nginx
  host: pgadmin.example.com
  tls:
    enabled: false
```

### 4. Create Registry Secret (if needed)

```bash
# Create namespace first
kubectl create namespace database

# Create registry secret
kubectl create secret docker-registry registry-secret \
  --docker-server=your-registry.example.com \
  --docker-username=your-username \
  --docker-password=your-password \
  --namespace=database
```

### 5. Install Chart

```bash
# Dry run to preview
helm install postgresql ./postgresql-pgadmin \
  --namespace database \
  --create-namespace \
  --values my-values.yaml \
  --dry-run --debug

# Install for real
helm install postgresql ./postgresql-pgadmin \
  --namespace database \
  --create-namespace \
  --values my-values.yaml

# Or with inline values
helm install postgresql ./postgresql-pgadmin \
  --namespace database \
  --create-namespace \
  --set postgresql.image.registry=registry.example.com \
  --set config.postgresPassword=mysecretpass \
  --set pgadminConfig.password=pgadminpass
```

### 6. Verify Installation

```bash
# Check release status
helm list -n database

# Get release information
helm status postgresql -n database

# View all resources
kubectl get all -n database

# Check pod status
kubectl get pods -n database -w

# View logs
kubectl logs -f postgresql-0 -n database -c postgresql
```

### 7. Access the Application

Follow the instructions from NOTES.txt (displayed after install):

```bash
# Get notes again
helm get notes postgresql -n database

# Port forward to access pgAdmin
kubectl port-forward -n database postgresql-0 8080:8080
```

## ⚙️ Configuration

### values.yaml Structure

The default `values.yaml` contains all configurable options:

```yaml
# Global settings
global:
  namespace: database

# PostgreSQL image
postgresql:
  image:
    registry: ""
    repository: postgresql
    tag: "18"
    pullPolicy: IfNotPresent
  
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
  
  # Security context
  securityContext:
    runAsUser: 1001
    runAsNonRoot: true
    fsGroup: 1001

# pgAdmin image
pgadmin:
  image:
    registry: ""
    repository: pgadmin
    tag: latest
    pullPolicy: IfNotPresent
  
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  
  service:
    type: ClusterIP
    port: 8080

# Image pull secrets
imagePullSecrets: []

# PostgreSQL configuration
config:
  postgresDatabase: postgres
  postgresUser: postgres
  postgresPassword: ""  # Set via --set or secret

# pgAdmin configuration
pgadminConfig:
  email: admin@example.com
  password: ""  # Set via --set or secret

# Persistence
persistence:
  enabled: true
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 10Gi
  annotations: {}

# Service configuration
service:
  postgresql:
    type: ClusterIP
    port: 5432
  pgadmin:
    type: ClusterIP
    port: 8080

# Ingress configuration
ingress:
  enabled: false
  className: nginx
  annotations: {}
  host: pgadmin.example.com
  path: /
  pathType: Prefix
  tls:
    enabled: false
    secretName: pgadmin-tls

# OpenShift route
route:
  enabled: false
  host: ""
  tls:
    enabled: true
    termination: edge

# Resource limits
resources:
  postgresql:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
  pgadmin:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"

# Node selector
nodeSelector: {}

# Tolerations
tolerations: []

# Affinity
affinity: {}

# Labels and annotations
labels: {}
annotations: {}
```

### Environment-Specific Values

### Development (values-dev.yaml)

```yaml
postgresql:
  image:
    registry: your-registry.example.com
    tag: "18-dev"

resources:
  postgresql:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  pgadmin:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "250m"

persistence:
  size: 5Gi

ingress:
  enabled: true
  host: pgadmin-dev.example.com
```

**Deploy:**

```bash
helm install postgresql-dev ./postgresql-pgadmin \
  --namespace database-dev \
  --create-namespace \
  --values values-dev.yaml \
  --set config.postgresPassword=dev-password
```

### Staging (values-staging.yaml)

```yaml
postgresql:
  image:
    registry: your-registry.example.com
    tag: "18"

persistence:
  storageClass: "fast"
  size: 20Gi

ingress:
  enabled: true
  host: pgadmin-staging.example.com
  tls:
    enabled: true
    secretName: pgadmin-staging-tls
```

**Deploy:**

```bash
helm install postgresql-staging ./postgresql-pgadmin \
  --namespace database-staging \
  --create-namespace \
  --values values-staging.yaml \
  --set config.postgresPassword=staging-password
```

### Production (values-production.yaml)

```yaml
postgresql:
  image:
    registry: your-registry.example.com
    repository: postgresql
    tag: "18"
    # Use image digest for immutability
    digest: "sha256:abc123..."

resources:
  postgresql:
    requests:
      memory: "4Gi"
      cpu: "2000m"
    limits:
      memory: "8Gi"
      cpu: "4000m"
  pgadmin:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 100Gi

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  host: pgadmin.production.example.com
  tls:
    enabled: true
    secretName: pgadmin-prod-tls

# Production labels
labels:
  environment: production
  backup: enabled
  monitoring: enabled

# Node affinity for dedicated nodes
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: workload
          operator: In
          values:
          - database
```

**Deploy:**

```bash
helm install postgresql ./postgresql-pgadmin \
  --namespace database \
  --create-namespace \
  --values values-production.yaml \
  --set config.postgresPassword=$POSTGRES_PASSWORD \
  --set pgadminConfig.password=$PGADMIN_PASSWORD
```

## 🔧 Advanced Usage

### Using Helm Secrets

Encrypt sensitive values:

```bash
# Install sops
brew install sops  # macOS
# Or download from https://github.com/mozilla/sops/releases

# Create secrets file
cat > secrets.yaml <<EOF
config:
  postgresPassword: my-secret-password
pgadminConfig:
  password: pgadmin-secret
EOF

# Encrypt with sops
sops -e -i secrets.yaml

# Install with encrypted secrets
helm secrets install postgresql ./postgresql-pgadmin \
  --namespace database \
  --values values-production.yaml \
  --values secrets.yaml
```

### Using External Secrets

Reference secrets from Vault, AWS Secrets Manager, etc.:

```yaml
# values.yaml
externalSecrets:
  enabled: true
  backend: vault
  vaultPath: secret/database/postgresql
```

### Helm Hooks

Add pre/post install/upgrade hooks:

```yaml
# templates/backup-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "postgresql.fullname" . }}-backup
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      containers:
      - name: backup
        image: postgres:16
        command: ["/bin/sh"]
        args:
        - -c
        - |
          pg_dumpall -h postgresql -U postgres > /backup/backup-$(date +%Y%m%d).sql
      restartPolicy: Never
```

### Subchart Dependencies

Add dependencies in `Chart.yaml`:

```yaml
dependencies:
- name: postgresql
  version: "12.1.0"
  repository: "https://charts.bitnami.com/bitnami"
  condition: postgresql.enabled
- name: pgpool
  version: "4.0.0"
  repository: "https://charts.bitnami.com/bitnami"
  condition: pgpool.enabled
```

Update dependencies:

```bash
helm dependency update ./postgresql-pgadmin/
```

### Template Functions

Use Helm template functions in manifests:

```yaml
# templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "postgresql.fullname" . }}-config
  labels:
    {{- include "postgresql.labels" . | nindent 4 }}
data:
  POSTGRES_DB: {{ .Values.config.postgresDatabase | quote }}
  POSTGRES_USER: {{ .Values.config.postgresUser | quote }}
  MAX_CONNECTIONS: {{ .Values.config.maxConnections | default "100" | quote }}
  {{- if .Values.config.customConfig }}
  custom.conf: |
    {{- .Values.config.customConfig | nindent 4 }}
  {{- end }}
```

### Conditional Resources

Enable/disable resources:

```yaml
# values.yaml
ingress:
  enabled: true

route:
  enabled: false
```

```yaml
# templates/ingress.yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "postgresql.fullname" . }}
# ...
{{- end }}
```

## 🛠️ Helm Commands Reference

### Install

```bash
# Basic install
helm install [RELEASE_NAME] [CHART]

# With custom values
helm install postgresql ./postgresql-pgadmin --values values.yaml

# With inline values
helm install postgresql ./postgresql-pgadmin --set key=value

# Dry run
helm install postgresql ./postgresql-pgadmin --dry-run --debug

# Create namespace
helm install postgresql ./postgresql-pgadmin --create-namespace --namespace database

# Wait for resources to be ready
helm install postgresql ./postgresql-pgadmin --wait --timeout 10m

# Generate name
helm install --generate-name ./postgresql-pgadmin
```

### Upgrade

```bash
# Basic upgrade
helm upgrade postgresql ./postgresql-pgadmin

# Upgrade with new values
helm upgrade postgresql ./postgresql-pgadmin --values values-v2.yaml

# Force upgrade
helm upgrade postgresql ./postgresql-pgadmin --force

# Reuse existing values
helm upgrade postgresql ./postgresql-pgadmin --reuse-values

# Reset values to chart defaults
helm upgrade postgresql ./postgresql-pgadmin --reset-values

# Install if not exists, upgrade if exists
helm upgrade --install postgresql ./postgresql-pgadmin
```

### Rollback

```bash
# List revisions
helm history postgresql -n database

# Rollback to previous version
helm rollback postgresql -n database

# Rollback to specific revision
helm rollback postgresql 2 -n database

# Rollback with wait
helm rollback postgresql --wait -n database
```

### Uninstall

```bash
# Uninstall release
helm uninstall postgresql -n database

# Keep history
helm uninstall postgresql -n database --keep-history

# Dry run
helm uninstall postgresql -n database --dry-run
```

### List

```bash
# List releases in namespace
helm list -n database

# List all releases in all namespaces
helm list --all-namespaces

# Show deleted releases
helm list --uninstalled

# Show all (including deleted)
helm list --all
```

### Get Information

```bash
# Get values
helm get values postgresql -n database

# Get all values (including defaults)
helm get values postgresql -n database --all

# Get manifest
helm get manifest postgresql -n database

# Get notes
helm get notes postgresql -n database

# Get hooks
helm get hooks postgresql -n database

# Get all information
helm get all postgresql -n database
```

### Show Chart Information

```bash
# Show chart README
helm show readme ./postgresql-pgadmin/

# Show chart values
helm show values ./postgresql-pgadmin/

# Show chart metadata
helm show chart ./postgresql-pgadmin/

# Show everything
helm show all ./postgresql-pgadmin/
```

### Template Rendering

```bash
# Render templates locally
helm template postgresql ./postgresql-pgadmin

# With values file
helm template postgresql ./postgresql-pgadmin --values values.yaml

# Debug mode
helm template postgresql ./postgresql-pgadmin --debug

# Validate (lint)
helm lint ./postgresql-pgadmin/

# Specific release name and namespace
helm template my-release ./postgresql-pgadmin --namespace production
```

### Testing

```bash
# Run tests
helm test postgresql -n database

# Show test logs
helm test postgresql -n database --logs
```

### Diff (with plugin)

```bash
# Show diff before upgrade
helm diff upgrade postgresql ./postgresql-pgadmin --values values-new.yaml

# Colored diff
helm diff upgrade postgresql ./postgresql-pgadmin --values values-new.yaml --color
```

## 📦 Chart Development

### Create New Chart

```bash
# Create chart skeleton
helm create mychart

# Remove example templates
rm -rf mychart/templates/*
```

### Chart.yaml

```yaml
apiVersion: v2
name: postgresql-pgadmin
description: PostgreSQL 18 with pgAdmin4
type: application
version: 1.0.0
appVersion: "18"

keywords:
  - postgresql
  - pgadmin
  - database

maintainers:
  - name: Your Name
    email: your.email@example.com

sources:
  - https://github.com/your-org/postgress

dependencies: []
```

### _helpers.tpl

Create reusable template functions:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "postgresql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "postgresql.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "postgresql.labels" -}}
helm.sh/chart: {{ include "postgresql.chart" . }}
{{ include "postgresql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgresql.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### Package Chart

```bash
# Package chart
helm package postgresql-pgadmin/

# Creates: postgresql-pgadmin-1.0.0.tgz

# Package with specific version
helm package postgresql-pgadmin/ --version 1.0.1

# Package and sign
helm package postgresql-pgadmin/ --sign --key 'your-key-name'
```

### Publish to Repository

```bash
# Create index
helm repo index .

# Upload to repository (HTTP server, S3, GitHub Pages, etc.)
# Example: GitHub Pages
git add postgresql-pgadmin-1.0.0.tgz index.yaml
git commit -m "Release version 1.0.0"
git push

# Add repository
helm repo add myrepo https://your-org.github.io/charts
helm repo update

# Install from repository
helm install postgresql myrepo/postgresql-pgadmin
```

## 🐛 Troubleshooting

### Helm Install Fails

```bash
# Debug with dry-run
helm install postgresql ./postgresql-pgadmin --dry-run --debug

# Check rendered templates
helm template postgresql ./postgresql-pgadmin | less

# Validate chart
helm lint ./postgresql-pgadmin/
```

### Template Rendering Errors

```bash
# Common issues:
# - Missing required values
# - Incorrect indentation
# - Invalid Go template syntax

# Debug specific template
helm template postgresql ./postgresql-pgadmin --show-only templates/statefulset.yaml
```

### Values Not Applied

```bash
# Check what values are being used
helm get values postgresql -n database

# Include default values
helm get values postgresql -n database --all

# Verify values file syntax
cat values.yaml | yq eval
```

### Release in Failed State

```bash
# Check release status
helm status postgresql -n database

# View history
helm history postgresql -n database

# Rollback
helm rollback postgresql -n database

# Or delete and reinstall
helm uninstall postgresql -n database
helm install postgresql ./postgresql-pgadmin --values values.yaml
```

### Upgrade Issues

```bash
# Use --force for stuck upgrades
helm upgrade postgresql ./postgresql-pgadmin --force

# Or delete and reinstall
helm uninstall postgresql -n database
helm install postgresql ./postgresql-pgadmin
```

### Image Pull Errors

```bash
# Verify image values
helm get values postgresql -n database | grep image

# Check imagePullSecrets
kubectl get secret registry-secret -n database

# Test manually
podman pull your-registry.example.com/postgresql:18
```

## 📊 Best Practices

### 1. Version Control

- Store charts in Git
- Tag releases
- Use semantic versioning
- Document changes in CHANGELOG

### 2. Values Organization

```yaml
# Group related settings
postgresql:
  image:
    registry: ""
    repository: postgresql
  config:
    database: postgres
    user: postgres
```

### 3. Security

- Never commit secrets to values.yaml
- Use `--set` or secrets management
- Use image digests for production
- Enable security contexts

### 4. Documentation

- Update README.md
- Document all values
- Provide examples
- Include NOTES.txt

### 5. Testing

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "postgresql.fullname" . }}-test-connection"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
  - name: test
    image: postgres:16
    command: ['psql']
    args:
      - -h
      - postgresql
      - -U
      - postgres
      - -c
      - SELECT 1;
  restartPolicy: Never
```

Run tests:

```bash
helm test postgresql -n database
```

## 🔗 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Hub](https://artifacthub.io/)
- [Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Helm Secrets Plugin](https://github.com/jkroepke/helm-secrets)

## 🎯 Next Steps

- Explore [Ansible deployment](ANSIBLE.md) for automation
- Set up CI/CD for chart releases
- Implement chart testing
- Create chart repository
- Add monitoring and backup charts

---

**Need help?** Open an issue on GitHub or consult the [main README](../README.md).
