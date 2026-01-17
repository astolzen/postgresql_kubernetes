# PostgreSQL 18 with pgAdmin4 - Kubernetes Deployment

Complete solution for deploying PostgreSQL 18 with pgAdmin4 web interface on Kubernetes and OpenShift, with multiple deployment methods and custom-built container images.

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_

## 🌟 Features

- **PostgreSQL 18** - Latest PostgreSQL version on Red Hat UBI9
- **pgAdmin4 9.11** - Modern web-based administration interface
- **Custom Container Images** - Self-built, rootless containers optimized for Kubernetes
- **Multiple Deployment Methods** - Choose what works best for you:
  - Raw Kubernetes manifests
  - Kustomize
  - Helm charts
  - Ansible playbooks
- **Security First** - Non-root containers, security contexts, and best practices
- **Production Ready** - Persistent storage, health checks, resource limits
- **OpenShift Compatible** - Works with restricted SCCs
- **Cloud Agnostic** - Runs on any Kubernetes distribution

## 📁 Project Structure

```
postgress/
├── podman/          # Container images (Containerfiles + build scripts)
├── kubernetes/      # Raw Kubernetes manifests
├── kustomize/       # Kustomize configuration
├── helm/            # Helm charts
├── ansible/         # Ansible playbooks
└── docs/            # Additional documentation
```

## 🚀 Quick Start

### Choose Your Deployment Method

| Method | Best For | Complexity | Flexibility |
|--------|----------|------------|-------------|
| [**Kubernetes**](docs/KUBERNETES.md) | Learning, simple deployments | ⭐ Low | ⭐⭐ Medium |
| [**Kustomize**](docs/KUSTOMIZE.md) | GitOps, environment variations | ⭐⭐ Medium | ⭐⭐⭐ High |
| [**Helm**](docs/HELM.md) | Package management, templating | ⭐⭐ Medium | ⭐⭐⭐⭐ Very High |
| [**Ansible**](docs/ANSIBLE.md) | Automation, existing Ansible workflows | ⭐⭐⭐ High | ⭐⭐⭐⭐ Very High |

### 1. Build Container Images

See [Podman Build Documentation](docs/PODMAN.md) for details.

```bash
cd podman/

# Build PostgreSQL image
podman build -t your-registry.example.com/postgresql:18 -f Containerfile.postgresql .

# Build pgAdmin image
podman build -t your-registry.example.com/pgadmin:latest -f Containerfile.pgadmin .

# Push to your registry
podman push your-registry.example.com/postgresql:18
podman push your-registry.example.com/pgadmin:latest
```

### 2. Deploy with Your Preferred Method

**Raw Kubernetes:**
```bash
cd kubernetes/
kubectl apply -f .
```

**Kustomize:**
```bash
kubectl apply -k kustomize/base
```

**Helm:**
```bash
helm install postgresql ./helm/postgresql-pgadmin \
  --set postgresql.image.registry=your-registry.example.com
```

**Ansible:**
```bash
cd ansible/
ansible-playbook playbooks/deploy-postgresql.yaml
```

## 📚 Documentation

- **[Podman Build Guide](docs/PODMAN.md)** - Building custom container images
- **[Kubernetes Deployment](docs/KUBERNETES.md)** - Raw Kubernetes manifests
- **[Kustomize Guide](docs/KUSTOMIZE.md)** - Kustomize-based deployment
- **[Helm Guide](docs/HELM.md)** - Helm chart deployment
- **[Ansible Guide](docs/ANSIBLE.md)** - Ansible playbook deployment

## ⚙️ Configuration

### Before Deployment

1. **Update Registry URLs** - Replace `your-registry.example.com` with your actual registry
2. **Set Passwords** - Change all `CHANGE_ME` values with secure passwords
3. **Configure Hostnames** - Update `pgadmin.example.com` to your actual hostname
4. **Set Resource Limits** - Adjust CPU and memory based on your needs
5. **Configure Storage** - Set appropriate storage class and size

### Registry Credentials

Create a secret for your private registry:

```bash
kubectl create secret docker-registry registry-secret \
  --docker-server=your-registry.example.com \
  --docker-username=your-username \
  --docker-password=your-password \
  --namespace=database
```

## 🔐 Security

This deployment follows security best practices:

- ✅ **Non-root containers** - Runs as unprivileged user
- ✅ **No privilege escalation** - Secure by default
- ✅ **Dropped capabilities** - Minimal permissions
- ✅ **Seccomp profiles** - Runtime security
- ✅ **Network policies** - (Optional) Restrict traffic
- ✅ **Secret management** - Credentials in Kubernetes secrets

### Production Security Checklist

- [ ] Change all default passwords
- [ ] Use strong, unique passwords
- [ ] Enable TLS for pgAdmin route/ingress
- [ ] Use external secret management (Vault, Sealed Secrets)
- [ ] Configure network policies
- [ ] Enable audit logging
- [ ] Regular security updates for images

## 📦 Components

### PostgreSQL 18

- **Base Image**: Red Hat UBI9
- **Version**: PostgreSQL 18.1
- **Port**: 5432
- **Storage**: Persistent volume (default 10Gi)
- **User**: postgres (UID 1001)

### pgAdmin4

- **Base Image**: Red Hat UBI9
- **Version**: pgAdmin 9.11
- **Port**: 8080 (non-privileged)
- **User**: pgadmin (UID 1001)
- **Access**: Web interface

## 🌐 Access

### PostgreSQL Database

Internal access (from within cluster):
```bash
Host: postgresql.database.svc.cluster.local
Port: 5432
Username: postgres
Database: postgres
```

Port forward for local access:
```bash
kubectl port-forward -n database postgresql-0 5432:5432
psql -h localhost -U postgres -d postgres
```

### pgAdmin Web Interface

- **URL**: http://pgadmin.example.com (configure your hostname)
- **Email**: admin@example.com
- **Password**: (set in secrets)

Port forward for local access:
```bash
kubectl port-forward -n database postgresql-0 8080:8080
# Open: http://localhost:8080
```

## 🛠️ Management

### View Resources

```bash
# View all resources
kubectl get all -n database

# View pod status
kubectl get pods -n database

# View services
kubectl get svc -n database

# View persistent volume claims
kubectl get pvc -n database
```

### View Logs

```bash
# PostgreSQL logs
kubectl logs -f postgresql-0 -n database -c postgresql

# pgAdmin logs
kubectl logs -f postgresql-0 -n database -c pgadmin4
```

### Connect to PostgreSQL

```bash
# Using kubectl exec
kubectl exec -it postgresql-0 -n database -c postgresql -- psql -U postgres

# Using psql client (after port-forward)
psql -h localhost -U postgres -d postgres
```

### Backup Database

```bash
# Create backup
kubectl exec postgresql-0 -n database -c postgresql -- \
  pg_dumpall -U postgres > backup-$(date +%Y%m%d).sql

# Restore backup
kubectl exec -i postgresql-0 -n database -c postgresql -- \
  psql -U postgres < backup-20260116.sql
```

## 🔄 Updates

### Update Container Images

```bash
# Build new images
cd podman/
podman build -t your-registry.example.com/postgresql:18.1 -f Containerfile.postgresql .

# Push to registry
podman push your-registry.example.com/postgresql:18.1

# Update deployment (varies by method)
kubectl set image statefulset/postgresql postgresql=your-registry.example.com/postgresql:18.1 -n database
```

### Update Configuration

Edit ConfigMap and restart pods:
```bash
kubectl edit configmap postgresql-config -n database
kubectl delete pod postgresql-0 -n database  # StatefulSet will recreate
```

## 🧹 Cleanup

### Remove Deployment (Keep Data)

```bash
# Kubernetes
kubectl delete -f kubernetes/ --ignore-not-found

# Kustomize
kubectl delete -k kustomize/base

# Helm
helm uninstall postgresql

# Ansible
ansible-playbook ansible/playbooks/undeploy-postgresql.yaml
```

### Remove Everything (Including Data)

```bash
kubectl delete namespace database
# WARNING: This deletes all data!
```

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod postgresql-0 -n database

# Check events
kubectl get events -n database --sort-by='.lastTimestamp'

# Check logs
kubectl logs postgresql-0 -n database -c postgresql
```

### Image Pull Errors

```bash
# Verify secret exists
kubectl get secret registry-secret -n database

# Check image URL in statefulset
kubectl get statefulset postgresql -n database -o yaml | grep image:
```

### Database Connection Issues

```bash
# Test from within cluster
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- \
  psql -h postgresql.database.svc.cluster.local -U postgres

# Check service
kubectl get svc postgresql -n database
kubectl get endpoints postgresql -n database
```

## 📊 Monitoring

### Prometheus Metrics

PostgreSQL metrics can be exposed using:
- [postgres_exporter](https://github.com/prometheus-community/postgres_exporter)
- [pgAdmin metrics endpoint](https://www.pgadmin.org/)

### Grafana Dashboards

Import community dashboards:
- PostgreSQL Database: Dashboard ID 9628
- PostgreSQL Overview: Dashboard ID 455

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided as-is under the MIT License.

## 🔗 Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [Podman Documentation](https://docs.podman.io/)

## ⭐ Support

If you find this project helpful, please give it a star on GitHub!

## 📮 Contact

For questions, issues, or suggestions, please open an issue on GitHub.
