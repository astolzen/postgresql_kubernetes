# Kustomize Configuration for PostgreSQL + pgAdmin4

This directory contains Kustomize configurations for deploying PostgreSQL 18 and pgAdmin4 on Kubernetes/OpenShift.

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_

## Structure

```
kustomize/
├── base/                           # Base configuration (common to all environments)
│   ├── kustomization.yaml         # Main Kustomize file
│   ├── namespace.yaml             # Namespace definition
│   ├── pvc.yaml                   # PersistentVolumeClaim
│   ├── statefulset.yaml           # StatefulSet with PostgreSQL and pgAdmin
│   ├── service-postgresql.yaml    # PostgreSQL service
│   ├── service-pgadmin.yaml       # pgAdmin service
│   ├── route-pgadmin.yaml         # OpenShift route for pgAdmin
│   ├── configmap.yaml             # PostgreSQL configuration
│   ├── postgresql-custom.conf     # Custom PostgreSQL settings
│   └── docker-config.json         # Docker registry credentials
│
└── overlays/                      # Environment-specific overlays
    └── production/                # Production environment
        ├── kustomization.yaml     # Production overrides
        └── route-patch.yaml       # TLS configuration for route
```

## Usage

### Preview Resources (Dry Run)

```bash
# Preview base configuration
kubectl kustomize kustomize/base

# Preview production overlay
kubectl kustomize kustomize/overlays/production
```

### Deploy Base Configuration

```bash
# Set your kubeconfig
export KUBECONFIG=/path/to/your/kubeconfig

# Apply base configuration
kubectl apply -k kustomize/base

# Or using kustomize directly
kustomize build kustomize/base | kubectl apply -f -
```

### Deploy Production Overlay

```bash
# Apply production configuration
kubectl apply -k kustomize/overlays/production

# Or using kustomize directly
kustomize build kustomize/overlays/production | kubectl apply -f -
```

### Update Deployment

```bash
# After making changes, reapply
kubectl apply -k kustomize/overlays/production

# Or force replace
kubectl replace -k kustomize/overlays/production --force
```

### Delete Deployment

```bash
# Delete everything
kubectl delete -k kustomize/base

# Or for production
kubectl delete -k kustomize/overlays/production
```

## Configuration

### Secrets

Secrets are generated using Kustomize's `secretGenerator`. Update the values in:
- `kustomize/base/kustomization.yaml` for base secrets
- `kustomize/overlays/production/kustomization.yaml` for production secrets

**IMPORTANT**: In production, use proper secret management tools like:
- Sealed Secrets
- External Secrets Operator
- HashiCorp Vault
- Cloud provider secret managers

### Images

Image references are managed through Kustomize's `images` field:

```yaml
images:
  - name: postgresql-image
    newName: registry.example.com/your-org/postgresql/pgsql-ubi9
    newTag: latest
```

To use a specific version:
```bash
cd kustomize/overlays/production
kustomize edit set image postgresql-image=registry.example.com/your-org/postgresql/pgsql-ubi9:v1.2.3
```

### ConfigMaps

PostgreSQL configuration is managed through:
1. Static ConfigMap: `kustomize/base/configmap.yaml`
2. Generated ConfigMap: Uses `postgresql-custom.conf` file

Edit `kustomize/base/postgresql-custom.conf` to change PostgreSQL settings.

### Registry Credentials

The `docker-config.json` file contains base64-encoded credentials for Quay.io.

To update:
```bash
# Generate new auth string
echo -n "username:password" | base64

# Update docker-config.json with the new auth value
```

Or create from kubectl:
```bash
kubectl create secret docker-registry quay-secret \
  --docker-server=registry.example.com \
  --docker-username=your-username \
  --docker-password='your-password-here' \
  --dry-run=client -o json | \
  jq -r '.data[".dockerconfigjson"]' | \
  base64 -d > kustomize/base/docker-config.json
```

## Customization Examples

### Change Storage Size

Edit `kustomize/overlays/production/kustomization.yaml`:

```yaml
patchesJson6902:
  - target:
      version: v1
      kind: PersistentVolumeClaim
      name: postgresql-pvc
    patch: |-
      - op: replace
        path: /spec/resources/requests/storage
        value: "50Gi"
```

### Change Resource Limits

Already configured in production overlay. Edit `kustomization.yaml`:

```yaml
patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: StatefulSet
      name: postgresql
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: "8Gi"
```

### Add Custom Labels

Edit `kustomization.yaml`:

```yaml
commonLabels:
  team: database-team
  cost-center: engineering
  backup: enabled
```

### Change Namespace

Edit `kustomization.yaml`:

```yaml
namespace: my-custom-namespace
```

## Verification

```bash
# Check all resources
kubectl get all -n database

# Check secrets (names will have hash suffix)
kubectl get secrets -n database

# Check configmaps (names will have hash suffix)
kubectl get configmaps -n database

# View generated secret content
kubectl get secret -n database -o yaml | grep postgresql-secret

# Describe statefulset
kubectl describe statefulset postgresql -n database
```

## Troubleshooting

### Secret/ConfigMap Changes Not Applied

Kustomize adds a hash suffix to generated secrets and configmaps. When content changes, a new resource is created and pods are automatically updated.

If changes aren't reflected:
```bash
# Force delete the pod
kubectl delete pod postgresql-0 -n database

# The StatefulSet will recreate it with new secrets/configmaps
```

### View Effective Configuration

```bash
# See what will be applied
kubectl kustomize kustomize/overlays/production

# Save to file for inspection
kubectl kustomize kustomize/overlays/production > /tmp/effective-config.yaml
```

### Validate Before Applying

```bash
# Dry-run
kubectl apply -k kustomize/overlays/production --dry-run=client

# Server-side dry-run (validates against API server)
kubectl apply -k kustomize/overlays/production --dry-run=server
```

## Best Practices

1. **Never commit real secrets** to version control
2. Use **overlays** for environment-specific configuration
3. Use **specific image tags** (not `latest`) in production
4. Enable **hash suffix** for ConfigMaps and Secrets (automatic rollout on changes)
5. Use **namePrefix** or **nameSuffix** to avoid conflicts
6. Test changes with `kubectl diff -k <path>` before applying

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Deploy to Production
  run: |
    kubectl kustomize kustomize/overlays/production | \
    kubectl apply -f -
```

### ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgresql
spec:
  source:
    repoURL: <your-repo>
    targetRevision: main
    path: kustomize/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: database
```

## Additional Resources

- [Kustomize Documentation](https://kustomize.io/)
- [Kubectl Kustomize Reference](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [OpenShift Kustomize](https://docs.openshift.com/container-platform/latest/applications/working_with_quotas.html)
