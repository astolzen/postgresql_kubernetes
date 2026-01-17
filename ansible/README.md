## PostgreSQL + pgAdmin Ansible Deployment

Ansible playbooks and Jinja2 templates for deploying PostgreSQL 18 with pgAdmin4 on Kubernetes/OpenShift.

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_


## Directory Structure

```
ansible/
├── playbooks/
│   ├── deploy-postgresql.yaml      # Main deployment playbook
│   └── undeploy-postgresql.yaml    # Undeployment playbook
├── templates/                      # Jinja2 templates for K8s resources
│   ├── namespace.yaml.j2
│   ├── secrets.yaml.j2
│   ├── configmap.yaml.j2
│   ├── pvc.yaml.j2
│   ├── statefulset.yaml.j2
│   ├── service.yaml.j2
│   └── route.yaml.j2
├── vars/
│   └── postgresql-vars.yaml        # All configuration variables
├── inventory/
│   └── hosts                       # Inventory file
├── ansible.cfg                     # Ansible configuration
├── requirements.yaml               # Required collections
└── README.md                       # This file
```

## Prerequisites

### 1. Install Ansible

```bash
# RHEL/CentOS
sudo dnf install ansible-core

# Ubuntu/Debian
sudo apt install ansible

# macOS
brew install ansible

# Via pip
pip3 install ansible
```

### 2. Install Required Collections

```bash
cd /mnt/f/sync/ast/podman/postgress/ansible
ansible-galaxy collection install -r requirements.yaml
```

### 3. Configure Kubernetes Access

Ensure you have kubectl/oc configured:

```bash
# Set KUBECONFIG
export KUBECONFIG=/path/to/your/kubeconfig

# Test access
kubectl cluster-info
# or
oc cluster-info
```

## Configuration

### Edit Variables

All configuration is in `vars/postgresql-vars.yaml`:

```bash
vi vars/postgresql-vars.yaml
```

Key variables to customize:

```yaml
# Namespace
namespace: database

# PostgreSQL credentials
postgresql:
  auth:
    username: postgres
    password: changeme-secure-password
    database: postgres

# pgAdmin credentials
pgadmin:
  auth:
    email: admin@example.com
    password: admin123
  route:
    host: pgadmin.apps.example.com

# Image pull secrets
image_pull_secrets:
  username: your-username
  password: "your-password-here"
```

## Usage

### Deploy PostgreSQL + pgAdmin

```bash
cd /mnt/f/sync/ast/podman/postgress/ansible

# Deploy with default variables
ansible-playbook playbooks/deploy-postgresql.yaml

# Deploy with custom variables file
ansible-playbook playbooks/deploy-postgresql.yaml \
  -e @vars/production-vars.yaml

# Deploy with inline variables
ansible-playbook playbooks/deploy-postgresql.yaml \
  -e "namespace=production-db" \
  -e "postgresql.auth.password=SecurePassword123"

# Verbose output
ansible-playbook playbooks/deploy-postgresql.yaml -vvv
```

### Undeploy

```bash
# Undeploy (keeps PVC and namespace)
ansible-playbook playbooks/undeploy-postgresql.yaml

# Undeploy and delete PVC
ansible-playbook playbooks/undeploy-postgresql.yaml \
  -e "delete_pvc=true"

# Undeploy and delete everything including namespace
ansible-playbook playbooks/undeploy-postgresql.yaml \
  -e "delete_pvc=true" \
  -e "delete_namespace=true"

# Non-interactive (skip confirmation)
ansible-playbook playbooks/undeploy-postgresql.yaml \
  --extra-vars="confirm_delete={'user_input': 'yes'}"
```

## Deployment Workflow

The deployment playbook performs these tasks:

1. **Validation** - Checks for kubectl/oc availability
2. **Namespace Creation** - Creates the target namespace
3. **Secrets** - Creates secrets for PostgreSQL, pgAdmin, and registry
4. **ConfigMap** - Creates PostgreSQL configuration
5. **PVC** - Creates persistent volume claim for data
6. **Services** - Creates ClusterIP services
7. **StatefulSet** - Deploys PostgreSQL and pgAdmin containers
8. **Route** - Creates OpenShift route (if enabled)
9. **Verification** - Waits for pods to be ready
10. **Summary** - Displays deployment information

## Variable Reference

### Common Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `namespace` | `database` | Kubernetes namespace |
| `app_name` | `postgresql-pgadmin` | Application name |
| `release_name` | `postgresql` | Release name for resources |

### PostgreSQL Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `postgresql.image.registry` | `registry.example.com` | Image registry |
| `postgresql.image.repository` | `your-org/postgresql/pgsql-ubi9` | Image repository |
| `postgresql.image.tag` | `latest` | Image tag |
| `postgresql.auth.username` | `postgres` | PostgreSQL username |
| `postgresql.auth.password` | `changeme-secure-password` | PostgreSQL password |
| `postgresql.auth.database` | `postgres` | Default database |
| `postgresql.persistence.size` | `10Gi` | PVC size |

### pgAdmin Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `pgadmin.image.registry` | `registry.example.com` | Image registry |
| `pgadmin.image.repository` | `your-org/postgresql/pgadmin` | Image repository |
| `pgadmin.auth.email` | `admin@example.com` | Login email |
| `pgadmin.auth.password` | `admin123` | Login password |
| `pgadmin.route.host` | `pgadmin.apps.example.com` | Route hostname |

## Examples

### Production Deployment

Create `vars/production-vars.yaml`:

```yaml
---
namespace: production-database

postgresql:
  auth:
    password: "{{ lookup('env', 'POSTGRES_PASSWORD') }}"
  persistence:
    size: 50Gi
    storage_class: "fast-ssd"
  resources:
    limits:
      memory: "4Gi"

pgadmin:
  auth:
    password: "{{ lookup('env', 'PGADMIN_PASSWORD') }}"
  route:
    host: pgadmin.production.example.com
    tls_enabled: true
```

Deploy:

```bash
export POSTGRES_PASSWORD="SuperSecret123"
export PGADMIN_PASSWORD="AdminSecret456"

ansible-playbook playbooks/deploy-postgresql.yaml \
  -e @vars/production-vars.yaml
```

### Development Deployment

```bash
ansible-playbook playbooks/deploy-postgresql.yaml \
  -e "namespace=dev-database" \
  -e "postgresql.persistence.size=5Gi" \
  -e "postgresql.resources.limits.memory=1Gi"
```

### Update Configuration

Edit variables and rerun the playbook:

```bash
# Update vars file
vi vars/postgresql-vars.yaml

# Reapply (updates existing resources)
ansible-playbook playbooks/deploy-postgresql.yaml
```

## Troubleshooting

### Check Playbook Syntax

```bash
ansible-playbook playbooks/deploy-postgresql.yaml --syntax-check
```

### Dry Run

```bash
ansible-playbook playbooks/deploy-postgresql.yaml --check
```

### Debug Mode

```bash
ansible-playbook playbooks/deploy-postgresql.yaml -vvv
```

### View Generated Manifests

The playbook creates temporary manifests that you can inspect:

```bash
# Add this task to the playbook to keep manifests
- name: Display manifest directory
  debug:
    var: temp_manifest_dir.path
```

### Common Issues

**Collection not found:**
```bash
ansible-galaxy collection install kubernetes.core
```

**Cannot connect to cluster:**
```bash
export KUBECONFIG=/path/to/your/kubeconfig
kubectl cluster-info
```

**Permission denied:**
```bash
# Ensure your user has proper RBAC permissions
kubectl auth can-i create statefulsets -n database
```

## Integration with CI/CD

### GitLab CI

```yaml
deploy:
  stage: deploy
  image: ansible/ansible-runner
  script:
    - ansible-galaxy collection install -r requirements.yaml
    - ansible-playbook playbooks/deploy-postgresql.yaml \
        -e "postgresql.auth.password=$POSTGRES_PASSWORD"
```

### GitHub Actions

```yaml
- name: Deploy PostgreSQL
  run: |
    ansible-galaxy collection install -r ansible/requirements.yaml
    ansible-playbook ansible/playbooks/deploy-postgresql.yaml
  env:
    KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

### Jenkins

```groovy
stage('Deploy') {
    steps {
        sh '''
            cd ansible
            ansible-galaxy collection install -r requirements.yaml
            ansible-playbook playbooks/deploy-postgresql.yaml \
              -e "postgresql.auth.password=${POSTGRES_PASSWORD}"
        '''
    }
}
```

## Accessing the Deployment

### PostgreSQL

```bash
# Port forward
kubectl port-forward -n database postgresql-0 5432:5432

# Connect
psql -h localhost -U postgres -d postgres
```

### pgAdmin

Access via route: http://pgadmin.apps.example.com

Or port forward:
```bash
kubectl port-forward -n database postgresql-0 8080:8080
# Open: http://localhost:8080
```

## Best Practices

1. **Use Ansible Vault** for sensitive data:
   ```bash
   ansible-vault encrypt vars/postgresql-vars.yaml
   ansible-playbook playbooks/deploy-postgresql.yaml --ask-vault-pass
   ```

2. **Version control** your variables (encrypted)

3. **Test in non-production** first

4. **Use specific image tags** in production (not `latest`)

5. **Backup data** before updates

6. **Use external secret management** (Vault, etc.)

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [kubernetes.core Collection](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
