# Kustomize Deployment Guide

This guide covers deploying PostgreSQL 18 and pgAdmin4 using Kustomize for managing Kubernetes configurations.

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_


## 📋 Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [Base Configuration](#base-configuration)
- [Overlays](#overlays)
- [Customization](#customization)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

## 📖 Introduction

### What is Kustomize?

Kustomize is a standalone tool to customize Kubernetes objects through a `kustomization.yaml` file. It allows you to:

- ✅ Manage multiple environments (dev, staging, production)
- ✅ Patch configurations without modifying base files
- ✅ Generate ConfigMaps and Secrets from files
- ✅ Apply common labels and annotations
- ✅ Compose and customize collections of Kubernetes resources

### Why Use Kustomize?

**Advantages:**
- No templating - pure Kubernetes YAML
- Built into kubectl (no additional tools required)
- Environment-specific overlays
- Clear separation of base and environment configs
- GitOps friendly

**Best For:**
- Teams managing multiple environments
- GitOps workflows (ArgoCD, Flux)
- Organizations preferring declarative configuration
- When you want environment-specific variations

## 🔧 Prerequisites

### Required Tools

**kubectl with Kustomize** (built-in since v1.14)

```bash
# Check kubectl version
kubectl version --client

# Verify Kustomize is available
kubectl kustomize --help
```

**Optional: Standalone Kustomize**

```bash
# Install standalone Kustomize (for latest features)
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Verify installation
kustomize version
```

### Cluster Requirements

- Kubernetes cluster (1.24+)
- kubectl configured to access your cluster
- Sufficient resources (CPU: 2 cores, Memory: 4GB)
- PersistentVolume support
- Container images available in a registry

## 📁 Directory Structure

```
kustomize/
├── base/                          # Base configuration
│   ├── kustomization.yaml         # Base kustomization file
│   ├── namespace.yaml             # Namespace definition
│   ├── statefulset.yaml           # PostgreSQL StatefulSet
│   ├── services.yaml              # Services for PostgreSQL and pgAdmin
│   ├── pvc.yaml                   # Persistent Volume Claim
│   ├── configmap.yaml             # PostgreSQL configuration
│   └── secrets.yaml               # Credentials (gitignored)
│
└── overlays/                      # Environment-specific overlays
    ├── development/               # Development environment
    │   ├── kustomization.yaml     # Dev-specific customizations
    │   ├── patches/               # Dev patches
    │   │   ├── resources.yaml     # Smaller resource limits
    │   │   └── storage.yaml       # Smaller storage
    │   └── secrets.env            # Dev secrets (gitignored)
    │
    ├── staging/                   # Staging environment
    │   ├── kustomization.yaml     # Staging customizations
    │   ├── patches/               # Staging patches
    │   │   └── replicas.yaml      # Same as production
    │   └── secrets.env            # Staging secrets (gitignored)
    │
    └── production/                # Production environment
        ├── kustomization.yaml     # Production customizations
        ├── patches/               # Production patches
        │   ├── resources.yaml     # Larger resource limits
        │   ├── storage.yaml       # Larger storage
        │   └── ingress-tls.yaml   # TLS configuration
        └── secrets.env            # Production secrets (gitignored)
```

## 🚀 Quick Start

### 1. Review Base Configuration

```bash
cd kustomize/

# View the base kustomization
cat base/kustomization.yaml

# Preview what will be deployed
kubectl kustomize base/
```

### 2. Customize for Your Environment

**Update image registry in overlays:**

```bash
# Edit overlay kustomization.yaml
vim overlays/development/kustomization.yaml
```

Update the images section:

```yaml
images:
- name: postgresql
  newName: your-registry.example.com/postgresql
  newTag: "18"
- name: pgadmin
  newName: your-registry.example.com/pgadmin
  newTag: latest
```

**Set secrets:**

```bash
# Create secrets file for development
cat > overlays/development/secrets.env <<EOF
POSTGRES_PASSWORD=dev-password-change-me
PGADMIN_EMAIL=admin@dev.example.com
PGADMIN_PASSWORD=dev-pgadmin-password-change-me
EOF

# Ensure secrets are not committed
echo "secrets.env" >> .gitignore
```

### 3. Deploy to Development

```bash
# Preview the deployment
kubectl kustomize overlays/development/

# Apply the configuration
kubectl apply -k overlays/development/

# Watch the deployment
kubectl get pods -n database -w
```

### 4. Verify Deployment

```bash
# Check all resources
kubectl get all -n database

# Check pod status
kubectl get pods -n database

# View logs
kubectl logs -f postgresql-0 -n database -c postgresql
kubectl logs -f postgresql-0 -n database -c pgadmin4

# Test PostgreSQL
kubectl exec -it postgresql-0 -n database -c postgresql -- psql -U postgres -c "SELECT version();"
```

### 5. Access pgAdmin

```bash
# Port forward
kubectl port-forward -n database postgresql-0 8080:8080

# Open in browser
open http://localhost:8080
```

## 🏗️ Base Configuration

### base/kustomization.yaml

The base kustomization defines common resources:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: database

resources:
- namespace.yaml
- configmap.yaml
- secrets.yaml
- pvc.yaml
- statefulset.yaml
- services.yaml

# Common labels applied to all resources
commonLabels:
  app: postgresql
  managed-by: kustomize

# Common annotations
commonAnnotations:
  documentation: "https://github.com/your-org/postgress"

# Generate ConfigMap from files
configMapGenerator:
- name: postgresql-config
  envs:
  - config.env

# Generate Secret from environment file
secretGenerator:
- name: postgresql-secret
  envs:
  - secrets.env

# Images (will be overridden by overlays)
images:
- name: postgresql
  newName: postgresql
  newTag: "18"
- name: pgadmin
  newName: pgadmin
  newTag: latest
```

### Base Resources

All base resources are standard Kubernetes manifests without environment-specific values.

**Key points:**
- Use placeholder image names (overridden by overlays)
- Use generic storage classes
- Use moderate resource requests/limits
- Include health checks
- Follow security best practices

## 🎨 Overlays

### Development Overlay

**Purpose:** Local development and testing

**overlays/development/kustomization.yaml:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: database

bases:
- ../../base

namePrefix: dev-
nameSuffix: ""

commonLabels:
  environment: development

images:
- name: postgresql
  newName: your-registry.example.com/postgresql
  newTag: "18-dev"
- name: pgadmin
  newName: your-registry.example.com/pgadmin
  newTag: latest

secretGenerator:
- name: postgresql-secret
  behavior: replace
  envs:
  - secrets.env

patches:
- path: patches/resources.yaml
- path: patches/storage.yaml

replicas:
- name: postgresql
  count: 1
```

**Key features:**
- Smaller resources (1 CPU, 2GB RAM)
- Smaller storage (5Gi)
- Development credentials
- Single replica
- Dev-specific image tags

**overlays/development/patches/resources.yaml:**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
spec:
  template:
    spec:
      containers:
      - name: postgresql
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      - name: pgadmin4
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"
```

**overlays/development/patches/storage.yaml:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  resources:
    requests:
      storage: 5Gi
```

### Staging Overlay

**Purpose:** Pre-production testing

**overlays/staging/kustomization.yaml:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: database-staging

bases:
- ../../base

namePrefix: staging-

commonLabels:
  environment: staging

images:
- name: postgresql
  newName: your-registry.example.com/postgresql
  newTag: "18"
- name: pgadmin
  newName: your-registry.example.com/pgadmin
  newTag: latest

secretGenerator:
- name: postgresql-secret
  behavior: replace
  envs:
  - secrets.env

patches:
- path: patches/resources.yaml

replicas:
- name: postgresql
  count: 1
```

**Key features:**
- Production-like resources
- Medium storage (10Gi)
- Staging credentials
- Staging-specific hostnames

### Production Overlay

**Purpose:** Production deployment

**overlays/production/kustomization.yaml:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: database

bases:
- ../../base

commonLabels:
  environment: production

commonAnnotations:
  monitoring: "enabled"
  backup: "enabled"

images:
- name: postgresql
  newName: your-registry.example.com/postgresql
  newTag: "18"
  digest: sha256:abcdef...  # Use digest for production
- name: pgadmin
  newName: your-registry.example.com/pgadmin
  newTag: "9.11"
  digest: sha256:123456...

secretGenerator:
- name: postgresql-secret
  behavior: replace
  envs:
  - secrets.env

patches:
- path: patches/resources.yaml
- path: patches/storage.yaml
- path: patches/ingress-tls.yaml

replicas:
- name: postgresql
  count: 1
```

**overlays/production/patches/resources.yaml:**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
spec:
  template:
    spec:
      containers:
      - name: postgresql
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
      - name: pgadmin4
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

**overlays/production/patches/storage.yaml:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  storageClassName: fast-ssd  # Production storage class
  resources:
    requests:
      storage: 100Gi
```

**overlays/production/patches/ingress-tls.yaml:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pgadmin
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - pgadmin.production.example.com
    secretName: pgadmin-tls-cert
  rules:
  - host: pgadmin.production.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: pgadmin
            port:
              number: 8080
```

**Key features:**
- Maximum resources (2-4 CPU, 4-8GB RAM)
- Large storage (100Gi)
- Production credentials (from sealed secrets or vault)
- TLS enabled
- Monitoring enabled
- Image digests for immutability

## ⚙️ Customization

### Change Image Registry

Edit the overlay's kustomization.yaml:

```yaml
images:
- name: postgresql
  newName: registry.your-company.com/postgresql
  newTag: "18.1"
- name: pgadmin
  newName: registry.your-company.com/pgadmin
  newTag: "9.11"
```

### Add ConfigMap from File

```yaml
configMapGenerator:
- name: postgresql-init
  files:
  - init-scripts/01-create-database.sql
  - init-scripts/02-create-users.sql
```

### Add Labels and Annotations

```yaml
commonLabels:
  team: database
  cost-center: engineering
  
commonAnnotations:
  contact: dba-team@example.com
  documentation: https://wiki.example.com/postgres
```

### Patch Specific Fields

**Using Strategic Merge Patch:**

```yaml
# patches/custom-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgresql-config
data:
  POSTGRES_MAX_CONNECTIONS: "200"
  POSTGRES_SHARED_BUFFERS: "512MB"
```

Reference in kustomization.yaml:

```yaml
patches:
- path: patches/custom-config.yaml
```

**Using JSON 6902 Patch:**

```yaml
# More precise patching
patches:
- target:
    group: apps
    version: v1
    kind: StatefulSet
    name: postgresql
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/resources/limits/memory
      value: 8Gi
```

### Add Init Containers

```yaml
# patches/init-container.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
spec:
  template:
    spec:
      initContainers:
      - name: init-permissions
        image: busybox:latest
        command: ['sh', '-c', 'chmod -R 700 /var/lib/postgresql/data']
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
```

### Generate Secrets from Literals

```yaml
secretGenerator:
- name: postgresql-secret
  literals:
  - POSTGRES_PASSWORD=my-secure-password
  - PGADMIN_PASSWORD=admin-password
```

**Note:** Not recommended for production - use external secret management.

## 🔧 Advanced Usage

### Multi-Environment Deployment

Deploy to multiple environments:

```bash
# Deploy to all environments
for env in development staging production; do
  echo "Deploying to $env..."
  kubectl apply -k overlays/$env/
done

# Or use a script
./deploy-all.sh
```

### Sealed Secrets Integration

For production, use Sealed Secrets:

```bash
# Install kubeseal
brew install kubeseal  # or download from releases

# Create sealed secret
kubectl create secret generic postgresql-secret \
  --from-literal=POSTGRES_PASSWORD=prod-password \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > overlays/production/sealed-secret.yaml

# Add to kustomization
echo "- sealed-secret.yaml" >> overlays/production/kustomization.yaml
```

### Helm Chart Integration

Use Kustomize with Helm charts:

```yaml
helmCharts:
- name: postgresql
  repo: https://charts.bitnami.com/bitnami
  version: 12.1.0
  releaseName: postgresql
  namespace: database
  valuesInline:
    auth:
      postgresPassword: change-me
```

### Components (Reusable Pieces)

Create reusable components:

```
kustomize/
├── components/
│   ├── monitoring/
│   │   ├── kustomization.yaml
│   │   ├── servicemonitor.yaml
│   │   └── prometheus-rules.yaml
│   └── backup/
│       ├── kustomization.yaml
│       ├── cronjob.yaml
│       └── backup-pvc.yaml
```

Use in overlays:

```yaml
components:
- ../../components/monitoring
- ../../components/backup
```

### GitOps with ArgoCD

**ArgoCD Application manifest:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgresql-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/postgress.git
    targetRevision: main
    path: kustomize/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: database
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### GitOps with Flux

**Flux Kustomization:**

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: postgresql-production
  namespace: flux-system
spec:
  interval: 10m
  path: ./kustomize/overlays/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: postgress
  healthChecks:
  - apiVersion: apps/v1
    kind: StatefulSet
    name: postgresql
    namespace: database
```

## 🛠️ Commands Reference

### Build and Preview

```bash
# Preview base configuration
kubectl kustomize base/

# Preview development overlay
kubectl kustomize overlays/development/

# Preview with standalone kustomize
kustomize build overlays/production/

# Save output to file
kubectl kustomize overlays/production/ > deployment.yaml
```

### Apply Configurations

```bash
# Apply base (not recommended)
kubectl apply -k base/

# Apply development overlay
kubectl apply -k overlays/development/

# Apply production overlay
kubectl apply -k overlays/production/

# Apply from remote URL
kubectl apply -k github.com/your-org/postgress/kustomize/overlays/production?ref=v1.0.0
```

### Delete Resources

```bash
# Delete development deployment
kubectl delete -k overlays/development/

# Delete production deployment
kubectl delete -k overlays/production/
```

### Diff Changes

```bash
# See what would change (requires kubectl diff)
kubectl diff -k overlays/production/

# Compare with server-side dry-run
kubectl apply -k overlays/production/ --dry-run=server
```

### Validate

```bash
# Validate kustomization
kubectl kustomize overlays/production/ > /dev/null && echo "Valid" || echo "Invalid"

# Validate with kubeval
kubectl kustomize overlays/production/ | kubeval

# Validate with kubeconform
kubectl kustomize overlays/production/ | kubeconform -strict -summary
```

## 🐛 Troubleshooting

### Kustomization Not Found

```bash
# Error: unable to find one of 'kustomization.yaml', 'kustomization.yml' or 'Kustomization'

# Solution: Ensure kustomization.yaml exists
ls -la kustomization.yaml

# Check spelling (case-sensitive)
```

### Image Not Found

```bash
# Error: image not found in configuration

# Solution: Check images section in kustomization.yaml
kubectl kustomize overlays/production/ | grep image:

# Ensure image names match those in base resources
```

### Patch Not Applied

```bash
# Patches might not apply if target doesn't match

# Debug: View intermediate output
kubectl kustomize overlays/production/

# Check patch target matches resource name
# Check API version and kind
```

### Secret Generation Failed

```bash
# Error: unable to load secrets from file

# Solution: Ensure secrets.env exists
ls -la overlays/production/secrets.env

# Check file format (KEY=value, one per line)
cat overlays/production/secrets.env
```

### Namespace Conflicts

```bash
# Error: namespace already exists

# Solution: Use existing namespace or change name
# In kustomization.yaml, either:
# - Remove namespace.yaml from resources
# - Or change namespace in kustomization.yaml
```

### Invalid YAML

```bash
# Validate YAML syntax
kubectl kustomize overlays/production/ | yamllint -

# Or use online validator
kubectl kustomize overlays/production/ | less
```

## 📊 Best Practices

### 1. Directory Organization

```
✅ Good:
kustomize/
├── base/           # Minimal, reusable base
└── overlays/       # Environment-specific changes

❌ Avoid:
kustomize/
├── dev/           # No clear base/overlay separation
├── prod/
```

### 2. Base Configuration

- Keep base minimal and generic
- No environment-specific values
- No secrets in base
- Use placeholder image names

### 3. Overlays

- One overlay per environment
- Environment-specific values only
- Use patches for differences
- Keep overlays small

### 4. Secrets Management

```
✅ Good:
- Use external secret management (Vault, Sealed Secrets)
- Generate secrets from files (gitignored)
- Use secret generator with behavior: replace

❌ Avoid:
- Committing secrets to Git
- Hardcoding secrets in YAML
```

### 5. Image Management

```yaml
✅ Good (Production):
images:
- name: postgresql
  newName: registry.example.com/postgresql
  newTag: "18.1"
  digest: sha256:abc123...  # Immutable

✅ Good (Development):
images:
- name: postgresql
  newTag: "18-dev"  # Flexible for dev

❌ Avoid:
images:
- name: postgresql
  newTag: latest  # Too generic for production
```

### 6. Resource Naming

```yaml
✅ Good:
namePrefix: prod-
nameSuffix: -v1

❌ Avoid:
# Changing prefixes/suffixes after deployment
# (Creates new resources instead of updating)
```

### 7. Patching

```yaml
✅ Good:
# Small, focused patches
patches:
- path: patches/resources.yaml
- path: patches/storage.yaml

❌ Avoid:
# Large patches that duplicate base config
```

## 🔄 Update Workflow

### 1. Update Base Configuration

```bash
# Edit base resources
vim base/statefulset.yaml

# Test with development overlay
kubectl kustomize overlays/development/ | kubectl diff -f -

# Apply to development
kubectl apply -k overlays/development/

# If successful, apply to staging
kubectl apply -k overlays/staging/

# Finally, apply to production
kubectl apply -k overlays/production/
```

### 2. Update Image Version

```bash
# Edit overlay kustomization.yaml
vim overlays/production/kustomization.yaml

# Change image tag
images:
- name: postgresql
  newTag: "18.2"  # Update version

# Apply
kubectl apply -k overlays/production/

# Watch rollout
kubectl rollout status statefulset/postgresql -n database
```

### 3. Update Secrets

```bash
# Edit secrets file
vim overlays/production/secrets.env

# Apply (will regenerate secret with new hash)
kubectl apply -k overlays/production/

# Restart pods to use new secret
kubectl rollout restart statefulset/postgresql -n database
```

## 📚 Additional Resources

- [Kustomize Documentation](https://kustomize.io/)
- [Kubectl Kustomize Guide](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [Kustomize GitHub](https://github.com/kubernetes-sigs/kustomize)
- [Kustomize Best Practices](https://kubectl.docs.kubernetes.io/guides/config_management/introduction/)
- [ArgoCD Kustomize Integration](https://argo-cd.readthedocs.io/en/stable/user-guide/kustomize/)

## 🎯 Next Steps

- Explore [Helm deployment](HELM.md) for templating approach
- Try [Ansible deployment](ANSIBLE.md) for automation
- Set up GitOps with ArgoCD or Flux
- Implement external secret management
- Add monitoring and backup components

---

**Need help?** Open an issue on GitHub or consult the [main README](../README.md).
