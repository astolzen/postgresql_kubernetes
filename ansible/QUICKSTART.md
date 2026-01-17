# Ansible Quick Start Guide

Deploy PostgreSQL + pgAdmin in 5 minutes!

## Prerequisites Check

```bash
# 1. Check Ansible is installed
ansible --version

# 2. Check Kubernetes access
export KUBECONFIG=/path/to/your/kubeconfig
kubectl cluster-info
```

## Installation

### Step 1: Install Required Collections

```bash
cd /mnt/f/sync/ast/podman/postgress/ansible
ansible-galaxy collection install -r requirements.yaml
```

### Step 2: Configure Variables (Optional)

Edit `vars/postgresql-vars.yaml` to customize:
- Passwords
- Namespace
- Resource limits
- Hostnames

```bash
vi vars/postgresql-vars.yaml
```

### Step 3: Deploy!

```bash
ansible-playbook playbooks/deploy-postgresql.yaml
```

That's it! The playbook will:
- ✅ Create namespace
- ✅ Generate secrets
- ✅ Deploy PostgreSQL
- ✅ Deploy pgAdmin4
- ✅ Create services and routes
- ✅ Wait for everything to be ready

## Access Your Deployment

### pgAdmin Web Interface

Default URL: http://pgadmin.apps.example.com

Default credentials:
- **Email:** admin@example.com
- **Password:** admin123

### PostgreSQL Database

```bash
# Port forward
kubectl port-forward -n database postgresql-0 5432:5432

# Connect
psql -h localhost -U postgres -d postgres
# Password: changeme-secure-password
```

## Quick Commands

```bash
# View pods
kubectl get pods -n database

# View services
kubectl get svc -n database

# View route
kubectl get route -n database

# PostgreSQL logs
kubectl logs -f postgresql-0 -n database -c postgresql

# pgAdmin logs
kubectl logs -f postgresql-0 -n database -c pgadmin4

# Connect to PostgreSQL
kubectl exec -it postgresql-0 -n database -c postgresql -- psql -U postgres
```

## Undeploy

```bash
# Remove deployment (keeps PVC)
ansible-playbook playbooks/undeploy-postgresql.yaml

# Remove everything including data
ansible-playbook playbooks/undeploy-postgresql.yaml \
  -e "delete_pvc=true" \
  -e "delete_namespace=true"
```

## Troubleshooting

### Playbook fails with "Collection not found"

```bash
ansible-galaxy collection install kubernetes.core
```

### Cannot connect to cluster

```bash
export KUBECONFIG=/path/to/your/kubeconfig
kubectl cluster-info
```

### Check what variables are being used

```bash
ansible-playbook playbooks/deploy-postgresql.yaml --list-tasks
ansible-playbook playbooks/deploy-postgresql.yaml -vvv
```

## Next Steps

- 📚 Read the full [README.md](README.md)
- 🔐 Change default passwords in production
- 📊 Monitor your deployment
- 💾 Set up backups
- 🔒 Enable TLS for pgAdmin route

## Need Help?

Check the comprehensive documentation in `README.md`
