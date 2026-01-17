# PostgreSQL 18 with pgAdmin4 Helm Chart

A Helm chart for deploying PostgreSQL 18 with pgAdmin4 web interface on Kubernetes and OpenShift.

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_

## Features

- **PostgreSQL 18** - Latest PostgreSQL version
- **pgAdmin4 9.11** - Modern web-based administration interface
- **OpenShift Ready** - Works with restricted SCCs
- **Non-root Containers** - Enhanced security
- **Persistent Storage** - Data persisted in PVC
- **Configurable** - Extensive customization options
- **Production Ready** - Resource limits, probes, security contexts

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistent storage)
- OpenShift 4.x+ (if using OpenShift Routes)

## Installing the Chart

### Quick Install

```bash
# Add your Helm repo (if packaged)
helm repo add myrepo https://charts.example.com
helm repo update

# Install the chart
helm install my-postgresql myrepo/postgresql-pgadmin

# Or install from local directory
helm install my-postgresql ./helm/postgresql-pgadmin
```

### Custom Installation

```bash
# Install with custom values
helm install my-postgresql ./helm/postgresql-pgadmin \
  --namespace database \
  --create-namespace \
  --set postgresql.auth.password=MySecretPassword \
  --set pgadmin.auth.password=AdminPassword123

# Install with custom values file
helm install my-postgresql ./helm/postgresql-pgadmin \
  -f my-values.yaml
```

### Install on OpenShift

```bash
helm install my-postgresql ./helm/postgresql-pgadmin \
  --set pgadmin.route.enabled=true \
  --set pgadmin.route.host=pgadmin.apps.mycluster.example.com
```

## Uninstalling the Chart

```bash
helm uninstall my-postgresql
```

This removes all the Kubernetes components but preserves the PVC by default.

To delete the PVC:
```bash
kubectl delete pvc -n database -l app.kubernetes.io/instance=my-postgresql
```

## Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Kubernetes namespace | `database` |
| `createNamespace` | Create namespace if it doesn't exist | `true` |
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.image.registry` | PostgreSQL image registry | `registry.example.com` |
| `postgresql.image.repository` | PostgreSQL image repository | `your-org/postgresql/pgsql-ubi9` |
| `postgresql.image.tag` | PostgreSQL image tag | `latest` |
| `postgresql.auth.username` | PostgreSQL username | `postgres` |
| `postgresql.auth.password` | PostgreSQL password | `changeme-secure-password` |
| `postgresql.auth.database` | Default database name | `postgres` |
| `postgresql.persistence.size` | PVC size | `10Gi` |
| `postgresql.resources.limits.memory` | PostgreSQL memory limit | `2Gi` |
| `postgresql.resources.requests.memory` | PostgreSQL memory request | `512Mi` |
| `pgadmin.enabled` | Enable pgAdmin4 | `true` |
| `pgadmin.image.registry` | pgAdmin image registry | `registry.example.com` |
| `pgadmin.image.repository` | pgAdmin image repository | `your-org/postgresql/pgadmin` |
| `pgadmin.image.tag` | pgAdmin image tag | `latest` |
| `pgadmin.auth.email` | pgAdmin login email | `admin@example.com` |
| `pgadmin.auth.password` | pgAdmin login password | `admin123` |
| `pgadmin.route.enabled` | Enable OpenShift Route | `true` |
| `pgadmin.route.host` | Route hostname | `pgadmin.apps.example.com` |
| `pgadmin.ingress.enabled` | Enable Ingress | `false` |

### Full Values Example

Create a `my-values.yaml` file:

```yaml
namespace: production-db

postgresql:
  auth:
    password: "SuperSecretPassword123!"
  
  persistence:
    size: 50Gi
    storageClass: "fast-ssd"
  
  resources:
    limits:
      memory: "4Gi"
      cpu: "2"
    requests:
      memory: "1Gi"
      cpu: "500m"
  
  config:
    maxConnections: 200
    sharedBuffers: "512MB"

pgadmin:
  auth:
    email: "dba@mycompany.com"
    password: "AdminSecure456!"
  
  route:
    enabled: true
    host: "pgadmin.mycompany.com"
    tls:
      enabled: true
      termination: edge
```

Install with this file:
```bash
helm install my-postgresql ./helm/postgresql-pgadmin -f my-values.yaml
```

## Upgrading

### Upgrade with New Values

```bash
helm upgrade my-postgresql ./helm/postgresql-pgadmin \
  --set postgresql.image.tag=v1.0.1
```

### Rollback

```bash
# View release history
helm history my-postgresql

# Rollback to previous version
helm rollback my-postgresql

# Rollback to specific revision
helm rollback my-postgresql 2
```

## Common Operations

### Change PostgreSQL Password

```bash
# Create new secret
kubectl create secret generic my-postgresql-postgresql \
  --from-literal=postgres-password=NewPassword123 \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart the pod
kubectl delete pod my-postgresql-0 -n database
```

### Scale PostgreSQL (Not Recommended)

PostgreSQL StatefulSet should typically run with 1 replica. For HA, use PostgreSQL replication.

```bash
# View current replicas
kubectl get statefulset my-postgresql -n database

# Not recommended: Scale to multiple replicas
helm upgrade my-postgresql ./helm/postgresql-pgadmin \
  --set statefulset.replicas=3
```

### Access PostgreSQL

```bash
# Get password
export POSTGRES_PASSWORD=$(kubectl get secret my-postgresql-postgresql -n database -o jsonpath="{.data.postgres-password}" | base64 -d)

# Connect via kubectl
kubectl exec -it my-postgresql-0 -n database -c postgresql -- psql -U postgres

# Port forward for local access
kubectl port-forward -n database my-postgresql-0 5432:5432

# Connect from local machine
PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -U postgres -d postgres
```

### Access pgAdmin

```bash
# Get the URL
kubectl get route my-postgresql-pgadmin -n database -o jsonpath='{.spec.host}'

# Or via port-forward
kubectl port-forward -n database my-postgresql-0 8080:8080
# Open: http://localhost:8080
```

### View Logs

```bash
# PostgreSQL logs
kubectl logs -f my-postgresql-0 -n database -c postgresql

# pgAdmin logs
kubectl logs -f my-postgresql-0 -n database -c pgadmin4
```

### Backup Database

```bash
# Create backup
kubectl exec my-postgresql-0 -n database -c postgresql -- \
  pg_dumpall -U postgres > backup-$(date +%Y%m%d).sql

# Restore backup
kubectl exec -i my-postgresql-0 -n database -c postgresql -- \
  psql -U postgres < backup-20260113.sql
```

## Security

### Change Default Passwords

**Important**: Always change default passwords in production!

```yaml
postgresql:
  auth:
    password: "YourSecurePostgresPassword"

pgadmin:
  auth:
    password: "YourSecurePgAdminPassword"
```

### Use External Secrets

For production, use external secret management:

```bash
# Using External Secrets Operator
kubectl create secret generic postgresql-external \
  --from-literal=password="$(vault kv get -field=password secret/db/postgres)"

# Reference in values
postgresql:
  existingSecret: postgresql-external
```

### Network Policies

Add network policies to restrict access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgresql-netpol
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: postgresql
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: database
    ports:
    - protocol: TCP
      port: 5432
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod my-postgresql-0 -n database

# Check events
kubectl get events -n database --sort-by='.lastTimestamp'

# Check logs
kubectl logs my-postgresql-0 -n database -c postgresql
```

### PVC Issues

```bash
# Check PVC status
kubectl get pvc -n database

# Describe PVC
kubectl describe pvc my-postgresql-pvc -n database

# Check storage class
kubectl get storageclass
```

### Image Pull Errors

```bash
# Check image pull secret
kubectl get secret quay-secret -n database

# Test image pull
kubectl run test --image=registry.example.com/your-org/postgresql/pgsql-ubi9:latest \
  --image-pull-policy=Always --dry-run=client
```

## Values Schema

For a complete list of values, run:

```bash
helm show values ./helm/postgresql-pgadmin
```

## Development

### Lint Chart

```bash
helm lint ./helm/postgresql-pgadmin
```

### Template Chart

```bash
# Render templates
helm template my-postgresql ./helm/postgresql-pgadmin

# Render with values
helm template my-postgresql ./helm/postgresql-pgadmin -f my-values.yaml

# Debug
helm template my-postgresql ./helm/postgresql-pgadmin --debug
```

### Package Chart

```bash
helm package ./helm/postgresql-pgadmin
```

## License

This chart is provided as-is under the MIT License.

## Links

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [Helm Documentation](https://helm.sh/docs/)
