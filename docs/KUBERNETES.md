# Kubernetes Deployment Guide

This guide covers deploying PostgreSQL 18 and pgAdmin4 using raw Kubernetes manifests.

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_


## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Deployment Steps](#deployment-steps)
- [Configuration](#configuration)
- [Manifest Files](#manifest-files)
- [Access and Usage](#access-and-usage)
- [Management](#management)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### Required Tools

- **kubectl** - Kubernetes command-line tool
  ```bash
  # Install kubectl
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  
  # Verify installation
  kubectl version --client
  ```

### Cluster Requirements

- Kubernetes cluster (1.24+)
- kubectl configured to access your cluster
- Sufficient resources:
  - CPU: 2 cores minimum
  - Memory: 4GB minimum
  - Storage: PersistentVolume support (10Gi minimum)
- (Optional) Ingress controller for external access
- (Optional) LoadBalancer support or NodePort access

### Image Requirements

You must have the container images available in a registry:

- PostgreSQL 18 image
- pgAdmin4 image

See [Podman Build Documentation](PODMAN.md) for building images.

## 🏗️ Architecture Overview

### Components

The deployment consists of the following Kubernetes resources:

```
database namespace
├── namespace.yaml         # Namespace definition
├── secrets.yaml           # Database and pgAdmin credentials
├── configmap.yaml         # PostgreSQL configuration
├── pvc.yaml              # Persistent storage claim
├── statefulset.yaml      # PostgreSQL StatefulSet with pgAdmin sidecar
├── service-postgresql.yaml  # PostgreSQL internal service
├── service-pgadmin.yaml    # pgAdmin service
├── route.yaml            # OpenShift route (optional)
└── ingress.yaml          # Kubernetes ingress (optional)
```

### Architecture Diagram

```
┌─────────────────────────────────────────────┐
│           Kubernetes Cluster                │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │      Namespace: database            │   │
│  │                                     │   │
│  │  ┌────────────────────────────┐    │   │
│  │  │   StatefulSet: postgresql  │    │   │
│  │  │                            │    │   │
│  │  │  ┌──────────────────────┐  │    │   │
│  │  │  │  Pod: postgresql-0   │  │    │   │
│  │  │  │                      │  │    │   │
│  │  │  │  ┌───────────────┐  │  │    │   │
│  │  │  │  │ PostgreSQL    │  │  │    │   │
│  │  │  │  │ Container     │  │  │    │   │
│  │  │  │  │ Port: 5432    │  │  │    │   │
│  │  │  │  └───────────────┘  │  │    │   │
│  │  │  │                      │  │    │   │
│  │  │  │  ┌───────────────┐  │  │    │   │
│  │  │  │  │ pgAdmin       │  │  │    │   │
│  │  │  │  │ Container     │  │  │    │   │
│  │  │  │  │ Port: 8080    │  │  │    │   │
│  │  │  │  └───────────────┘  │  │    │   │
│  │  │  │                      │  │    │   │
│  │  │  │  PVC: postgres-data  │  │    │   │
│  │  │  └──────────────────────┘  │    │   │
│  │  └────────────────────────────┘    │   │
│  │                                     │   │
│  │  ┌────────────────────────────┐    │   │
│  │  │ Service: postgresql        │    │   │
│  │  │ Port: 5432                 │    │   │
│  │  └────────────────────────────┘    │   │
│  │                                     │   │
│  │  ┌────────────────────────────┐    │   │
│  │  │ Service: pgadmin           │    │   │
│  │  │ Port: 8080                 │    │   │
│  │  └────────────────────────────┘    │   │
│  │                                     │   │
│  │  ┌────────────────────────────┐    │   │
│  │  │ Ingress/Route: pgadmin     │    │   │
│  │  └────────────────────────────┘    │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## 🚀 Deployment Steps

### Step 1: Review and Customize Manifests

Navigate to the kubernetes directory:

```bash
cd kubernetes/
```

**Required customizations:**

1. **Registry URL** - Update image references in `statefulset.yaml`:
   ```yaml
   image: your-registry.example.com/postgresql:18
   image: your-registry.example.com/pgadmin:latest
   ```

2. **Passwords** - Update `secrets.yaml` with strong passwords:
   ```bash
   # Generate secure passwords
   echo -n "your-secure-password" | base64
   
   # Update secrets.yaml with the base64 encoded values
   ```

3. **Hostname** - Update `ingress.yaml` or `route.yaml`:
   ```yaml
   host: pgadmin.your-domain.com
   ```

4. **Storage** - Review `pvc.yaml` and adjust size/storageClassName:
   ```yaml
   storageClassName: your-storage-class  # e.g., gp3, standard
   resources:
     requests:
       storage: 10Gi  # Adjust as needed
   ```

### Step 2: Create Registry Secret (if using private registry)

If your images are in a private registry:

```bash
kubectl create namespace database

kubectl create secret docker-registry registry-secret \
  --docker-server=your-registry.example.com \
  --docker-username=your-username \
  --docker-password=your-password \
  --namespace=database
```

### Step 3: Apply Manifests

Deploy all resources:

```bash
# Apply all manifests
kubectl apply -f kubernetes/

# Or apply in order
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/pvc.yaml
kubectl apply -f kubernetes/statefulset.yaml
kubectl apply -f kubernetes/service-postgresql.yaml
kubectl apply -f kubernetes/service-pgadmin.yaml

# For Kubernetes (not OpenShift)
kubectl apply -f kubernetes/ingress.yaml

# For OpenShift
kubectl apply -f kubernetes/route.yaml
```

### Step 4: Verify Deployment

```bash
# Check namespace
kubectl get namespace database

# Check all resources
kubectl get all -n database

# Check pod status
kubectl get pods -n database -w

# Check services
kubectl get svc -n database

# Check persistent volume claims
kubectl get pvc -n database

# Check ingress/route
kubectl get ingress -n database  # Kubernetes
kubectl get route -n database    # OpenShift
```

Wait for the pod to be in `Running` state and `2/2` containers ready.

### Step 5: Verify Logs

```bash
# PostgreSQL logs
kubectl logs -f postgresql-0 -n database -c postgresql

# pgAdmin logs
kubectl logs -f postgresql-0 -n database -c pgadmin4

# All containers in pod
kubectl logs -f postgresql-0 -n database --all-containers=true
```

## ⚙️ Configuration

### secrets.yaml

Contains sensitive credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-secret
  namespace: database
type: Opaque
stringData:
  postgres-password: "CHANGE_ME"        # PostgreSQL password
  pgadmin-email: "admin@example.com"    # pgAdmin login email
  pgadmin-password: "CHANGE_ME"         # pgAdmin login password
```

**Security Best Practices:**
- Use strong, unique passwords
- Consider using external secret management (Vault, Sealed Secrets)
- Never commit secrets to version control
- Rotate passwords regularly

### configmap.yaml

PostgreSQL configuration parameters:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgresql-config
  namespace: database
data:
  POSTGRES_DB: "postgres"
  POSTGRES_USER: "postgres"
  PGDATA: "/var/lib/postgresql/data/pgdata"
  # Add custom PostgreSQL settings
  # postgresql.conf: |
  #   max_connections = 100
  #   shared_buffers = 256MB
```

### pvc.yaml

Persistent storage configuration:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: database
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard  # Change based on your cluster
  resources:
    requests:
      storage: 10Gi  # Adjust size as needed
```

**Storage Classes by Provider:**
- **AWS EKS**: `gp3`, `gp2`
- **Google GKE**: `standard`, `premium-rwo`
- **Azure AKS**: `managed-csi`, `default`
- **OpenShift**: `gp2`, `standard`
- **On-premise**: Depends on storage provisioner

### statefulset.yaml

Main deployment configuration:

**Key settings:**
```yaml
replicas: 1  # PostgreSQL doesn't support multiple replicas without replication setup

resources:
  postgresql:
    limits:
      memory: "2Gi"
      cpu: "1000m"
    requests:
      memory: "1Gi"
      cpu: "500m"
  
  pgadmin4:
    limits:
      memory: "1Gi"
      cpu: "500m"
    requests:
      memory: "512Mi"
      cpu: "250m"
```

Adjust resources based on your workload.

### service-postgresql.yaml

Internal database service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  namespace: database
spec:
  type: ClusterIP  # Internal only
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgresql
```

**Access from within cluster:**
- Hostname: `postgresql.database.svc.cluster.local`
- Port: `5432`

### service-pgadmin.yaml

pgAdmin web interface service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: pgadmin
  namespace: database
spec:
  type: ClusterIP  # Use LoadBalancer for external access without ingress
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: postgresql
```

### ingress.yaml

External access via Ingress (Kubernetes):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pgadmin
  namespace: database
  annotations:
    # nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx  # Adjust based on your ingress controller
  rules:
  - host: pgadmin.example.com  # Change to your hostname
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: pgadmin
            port:
              number: 8080
  # tls:
  # - hosts:
  #   - pgadmin.example.com
  #   secretName: pgadmin-tls
```

### route.yaml

External access via Route (OpenShift):

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: pgadmin
  namespace: database
spec:
  host: pgadmin.apps.your-cluster.com  # Change to your hostname
  to:
    kind: Service
    name: pgadmin
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

## 🌐 Access and Usage

### Access PostgreSQL Database

**From within the cluster:**

```bash
# Get a shell in the PostgreSQL container
kubectl exec -it postgresql-0 -n database -c postgresql -- psql -U postgres

# Run SQL commands
kubectl exec -it postgresql-0 -n database -c postgresql -- \
  psql -U postgres -c "SELECT version();"
```

**From your local machine (port-forward):**

```bash
# Forward port 5432
kubectl port-forward -n database postgresql-0 5432:5432

# In another terminal, connect with psql
psql -h localhost -U postgres -d postgres

# Or using a database client
# Host: localhost
# Port: 5432
# User: postgres
# Database: postgres
```

**Connection string format:**

```
postgresql://postgres:password@postgresql.database.svc.cluster.local:5432/postgres
```

### Access pgAdmin Web Interface

**Via Ingress/Route:**

Open your browser and navigate to:
- Kubernetes: `http://pgadmin.your-domain.com`
- OpenShift: `https://pgadmin.apps.your-cluster.com`

**Via Port Forward:**

```bash
# Forward port 8080
kubectl port-forward -n database postgresql-0 8080:8080

# Open in browser
open http://localhost:8080
```

**Login credentials:**
- Email: (from secrets.yaml)
- Password: (from secrets.yaml)

**Add PostgreSQL server in pgAdmin:**

1. Login to pgAdmin
2. Click "Add New Server"
3. General tab:
   - Name: `PostgreSQL`
4. Connection tab:
   - Host: `localhost` (pgAdmin is in same pod)
   - Port: `5432`
   - Username: `postgres`
   - Password: (from secrets.yaml)
   - Save password: Yes
5. Click "Save"

### Via Service (LoadBalancer)

If you change service type to LoadBalancer:

```bash
# Get external IP
kubectl get svc pgadmin -n database

# Access via external IP
open http://<EXTERNAL-IP>:8080
```

## 🛠️ Management

### Scale StatefulSet

**Note:** PostgreSQL doesn't support horizontal scaling without replication setup.

For read replicas, you would need to:
1. Configure PostgreSQL streaming replication
2. Create separate StatefulSet for replicas
3. Use different service for read-only access

### Update Images

```bash
# Update PostgreSQL image
kubectl set image statefulset/postgresql \
  postgresql=your-registry.example.com/postgresql:18.1 \
  -n database

# Update pgAdmin image
kubectl set image statefulset/postgresql \
  pgadmin4=your-registry.example.com/pgadmin:9.12 \
  -n database

# Check rollout status
kubectl rollout status statefulset/postgresql -n database

# Rollback if needed
kubectl rollout undo statefulset/postgresql -n database
```

### Update Configuration

```bash
# Edit ConfigMap
kubectl edit configmap postgresql-config -n database

# Edit Secrets
kubectl edit secret postgresql-secret -n database

# Restart pods to apply changes
kubectl delete pod postgresql-0 -n database
# StatefulSet will automatically recreate the pod
```

### Backup Database

```bash
# Create backup
kubectl exec postgresql-0 -n database -c postgresql -- \
  pg_dumpall -U postgres > backup-$(date +%Y%m%d-%H%M%S).sql

# Backup specific database
kubectl exec postgresql-0 -n database -c postgresql -- \
  pg_dump -U postgres -d postgres > backup-postgres-$(date +%Y%m%d-%H%M%S).sql

# Compressed backup
kubectl exec postgresql-0 -n database -c postgresql -- \
  pg_dumpall -U postgres | gzip > backup-$(date +%Y%m%d-%H%M%S).sql.gz
```

### Restore Database

```bash
# Restore from backup
kubectl exec -i postgresql-0 -n database -c postgresql -- \
  psql -U postgres < backup-20260116-120000.sql

# Restore compressed backup
gunzip -c backup-20260116-120000.sql.gz | \
  kubectl exec -i postgresql-0 -n database -c postgresql -- \
  psql -U postgres
```

### View Metrics

```bash
# Resource usage
kubectl top pod postgresql-0 -n database --containers

# Storage usage
kubectl exec postgresql-0 -n database -c postgresql -- \
  du -sh /var/lib/postgresql/data

# Database size
kubectl exec postgresql-0 -n database -c postgresql -- \
  psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('postgres'));"
```

## 🧹 Cleanup

### Remove Deployment (Keep Data)

```bash
# Delete all resources except PVC
kubectl delete statefulset postgresql -n database
kubectl delete service postgresql pgadmin -n database
kubectl delete ingress pgadmin -n database  # or route
kubectl delete configmap postgresql-config -n database
kubectl delete secret postgresql-secret -n database

# PVC remains - data is preserved
```

### Complete Removal (Including Data)

```bash
# Delete entire namespace (WARNING: Deletes all data!)
kubectl delete namespace database

# Or delete resources individually
kubectl delete -f kubernetes/
```

### Remove Only pgAdmin

If you want to remove pgAdmin but keep PostgreSQL:

```bash
# Edit StatefulSet to remove pgadmin container
kubectl edit statefulset postgresql -n database
# Remove the pgadmin4 container section

# Delete pgAdmin service and ingress
kubectl delete service pgadmin -n database
kubectl delete ingress pgadmin -n database
```

## 🐛 Troubleshooting

### Pod Not Starting

```bash
# Describe pod to see events
kubectl describe pod postgresql-0 -n database

# Common issues:
# - Image pull errors (check registry credentials)
# - Insufficient resources
# - PVC binding issues
# - InitContainer failures
```

### Image Pull Errors

```bash
# Check secret
kubectl get secret registry-secret -n database

# Verify secret is referenced in statefulset
kubectl get statefulset postgresql -n database -o yaml | grep imagePullSecrets

# Test image pull manually
podman pull your-registry.example.com/postgresql:18
```

### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n database

# Check PV availability
kubectl get pv

# Describe PVC for events
kubectl describe pvc postgres-data -n database

# Check storage class
kubectl get storageclass
```

### Database Connection Issues

```bash
# Check if PostgreSQL is running
kubectl exec postgresql-0 -n database -c postgresql -- pg_isready -U postgres

# Check PostgreSQL logs
kubectl logs postgresql-0 -n database -c postgresql

# Test connection from within pod
kubectl exec -it postgresql-0 -n database -c postgresql -- \
  psql -U postgres -c "SELECT 1;"

# Check service endpoints
kubectl get endpoints postgresql -n database
```

### pgAdmin Won't Start

```bash
# Check logs
kubectl logs postgresql-0 -n database -c pgadmin4

# Common issues:
# - Missing email/password in secrets
# - Port conflict
# - Permission issues
# - Python errors

# Restart container
kubectl delete pod postgresql-0 -n database
```

### Can't Access via Ingress

```bash
# Check ingress status
kubectl get ingress pgadmin -n database
kubectl describe ingress pgadmin -n database

# Check ingress controller
kubectl get pods -n ingress-nginx  # or your ingress namespace

# Test service directly
kubectl port-forward -n database postgresql-0 8080:8080
open http://localhost:8080
```

### Performance Issues

```bash
# Check resource limits
kubectl describe pod postgresql-0 -n database

# View resource usage
kubectl top pod postgresql-0 -n database --containers

# Check PostgreSQL stats
kubectl exec postgresql-0 -n database -c postgresql -- \
  psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# Check slow queries
kubectl exec postgresql-0 -n database -c postgresql -- \
  psql -U postgres -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

### Disk Space Issues

```bash
# Check disk usage
kubectl exec postgresql-0 -n database -c postgresql -- df -h

# Check database sizes
kubectl exec postgresql-0 -n database -c postgresql -- \
  psql -U postgres -c "\l+"

# Check table sizes
kubectl exec postgresql-0 -n database -c postgresql -- \
  psql -U postgres -c "\dt+"

# Clean up if needed
kubectl exec postgresql-0 -n database -c postgresql -- \
  psql -U postgres -c "VACUUM FULL;"
```

## 📊 Monitoring

### Health Checks

The StatefulSet includes liveness and readiness probes:

```yaml
livenessProbe:
  exec:
    command: ["pg_isready", "-U", "postgres"]
  initialDelaySeconds: 30
  periodSeconds: 10
  
readinessProbe:
  exec:
    command: ["pg_isready", "-U", "postgres"]
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Prometheus Metrics

To expose PostgreSQL metrics:

1. Deploy postgres_exporter as sidecar
2. Add ServiceMonitor for Prometheus
3. Configure dashboards in Grafana

Example ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgresql
  namespace: database
spec:
  selector:
    matchLabels:
      app: postgresql
  endpoints:
  - port: metrics
    interval: 30s
```

## 🔐 Security Hardening

### Network Policies

Restrict network access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgresql-network-policy
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: postgresql
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: application  # Allow only from app namespace
    ports:
    - protocol: TCP
      port: 5432
```

### Pod Security Standards

The StatefulSet includes security contexts:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  seccompProfile:
    type: RuntimeDefault

containerSecurityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
```

### TLS for pgAdmin

Add TLS certificate to ingress:

```yaml
spec:
  tls:
  - hosts:
    - pgadmin.your-domain.com
    secretName: pgadmin-tls-cert
```

## 📝 Next Steps

- **High Availability**: Consider [Patroni](https://patroni.readthedocs.io/) for HA PostgreSQL
- **Backup Automation**: Set up [pgBackRest](https://pgbackrest.org/) or Velero
- **Monitoring**: Integrate with Prometheus and Grafana
- **CI/CD**: Automate deployments with GitOps (ArgoCD, Flux)
- **Alternative Methods**: Try [Kustomize](KUSTOMIZE.md), [Helm](HELM.md), or [Ansible](ANSIBLE.md)

## 🔗 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [StatefulSet Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Persistent Volumes Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
