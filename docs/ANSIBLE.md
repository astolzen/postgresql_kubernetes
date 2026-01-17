# Ansible Deployment Guide

This guide covers deploying PostgreSQL 18 and pgAdmin4 using Ansible playbooks for automation and configuration management.

_AI Tools like Claude, Gemini, Ollama, qwen3-coder, gpt-oss, Continue and Cursor AI assisted in the generation of this Code and Documentation_


## 📋 Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [Playbooks](#playbooks)
- [Variables](#variables)
- [Inventory](#inventory)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

## 📖 Introduction

### What is Ansible?

Ansible is an automation tool that allows you to:

- ✅ Automate deployment and configuration
- ✅ Manage infrastructure as code
- ✅ Use simple YAML syntax (no programming required)
- ✅ Agentless architecture (SSH-based)
- ✅ Idempotent operations
- ✅ Integrate with existing workflows

### Why Use Ansible?

**Advantages:**
- Simple, human-readable YAML
- No agents required on target systems
- Large ecosystem of modules
- Easy integration with CI/CD
- Powerful variable management
- Role-based organization

**Best For:**
- Organizations already using Ansible
- Automated, repeatable deployments
- Managing multiple environments
- Integration with configuration management
- Infrastructure as Code workflows

## 🔧 Prerequisites

### Install Ansible

```bash
# Install Ansible (requires Python 3)
# Using pip
pip3 install ansible

# Using package manager
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# RHEL/CentOS/Fedora
sudo dnf install ansible

# macOS
brew install ansible

# Verify installation
ansible --version
```

### Install Required Collections

```bash
# Navigate to ansible directory
cd ansible/

# Install Kubernetes collection
ansible-galaxy collection install kubernetes.core

# Or install from requirements file
ansible-galaxy collection install -r requirements.yaml

# Verify installation
ansible-galaxy collection list
```

### Additional Tools

```bash
# kubectl (required for kubernetes.core collection)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

### Cluster Requirements

- Kubernetes cluster (1.24+)
- kubectl configured (`~/.kube/config`)
- Sufficient cluster resources
- PersistentVolume support
- Container images available in registry

## 📁 Directory Structure

```
ansible/
├── ansible.cfg                # Ansible configuration
├── requirements.yaml          # Required collections
├── inventory/                 # Inventory files
│   ├── development/           # Development inventory
│   │   ├── hosts.yaml         # Hosts definition
│   │   └── group_vars/        # Group variables
│   │       └── all.yaml
│   ├── staging/               # Staging inventory
│   │   ├── hosts.yaml
│   │   └── group_vars/
│   │       └── all.yaml
│   └── production/            # Production inventory
│       ├── hosts.yaml
│       └── group_vars/
│           └── all.yaml
│
├── playbooks/                 # Playbooks
│   ├── deploy-postgresql.yaml      # Main deployment playbook
│   ├── undeploy-postgresql.yaml    # Removal playbook
│   ├── update-images.yaml          # Update images
│   ├── backup-database.yaml        # Backup database
│   └── restore-database.yaml       # Restore database
│
├── templates/                 # Jinja2 templates
│   ├── namespace.yaml.j2      # Namespace template
│   ├── configmap.yaml.j2      # ConfigMap template
│   ├── secrets.yaml.j2        # Secrets template
│   ├── pvc.yaml.j2           # PVC template
│   ├── statefulset.yaml.j2   # StatefulSet template
│   ├── services.yaml.j2      # Services template
│   └── ingress.yaml.j2       # Ingress template
│
├── vars/                      # Variable files
│   ├── common.yaml           # Common variables
│   ├── development.yaml      # Development overrides
│   ├── staging.yaml         # Staging overrides
│   └── production.yaml      # Production overrides
│
└── README.md                 # Documentation
```

## 🚀 Quick Start

### 1. Configure Inventory

Edit the appropriate inventory file:

```bash
cd ansible/

# For development
vim inventory/development/group_vars/all.yaml
```

Update variables:

```yaml
# Kubernetes configuration
k8s_namespace: database
k8s_context: your-cluster-context

# Image configuration
postgresql_image_registry: your-registry.example.com
postgresql_image_repository: postgresql
postgresql_image_tag: "18"

pgadmin_image_registry: your-registry.example.com
pgadmin_image_repository: pgadmin
pgadmin_image_tag: latest

# Storage configuration
storage_class: standard
storage_size: 10Gi

# Credentials (use Ansible Vault in production)
postgres_password: "CHANGE_ME"
pgadmin_email: "admin@example.com"
pgadmin_password: "CHANGE_ME"

# Ingress configuration
ingress_enabled: true
ingress_class: nginx
ingress_host: pgadmin.dev.example.com
ingress_tls_enabled: false
```

### 2. Create Ansible Vault for Secrets (Recommended)

```bash
# Create vault password file
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass

# Create encrypted variables file
ansible-vault create inventory/development/group_vars/vault.yaml

# Add sensitive variables
postgres_password: "secure-password"
pgadmin_password: "secure-pgadmin-password"
```

Update `all.yaml` to reference vault variables:

```yaml
# Use vault variables
postgres_password: "{{ vault_postgres_password }}"
pgadmin_password: "{{ vault_pgadmin_password }}"
```

### 3. Test Connectivity

```bash
# Ping localhost (Ansible connects to localhost to manage k8s)
ansible all -i inventory/development/hosts.yaml -m ping

# Test kubectl access
kubectl cluster-info
```

### 4. Deploy PostgreSQL

```bash
# Dry run (check mode)
ansible-playbook playbooks/deploy-postgresql.yaml \
  -i inventory/development/hosts.yaml \
  --check

# Deploy
ansible-playbook playbooks/deploy-postgresql.yaml \
  -i inventory/development/hosts.yaml

# With vault
ansible-playbook playbooks/deploy-postgresql.yaml \
  -i inventory/development/hosts.yaml \
  --vault-password-file .vault_pass

# With extra variables
ansible-playbook playbooks/deploy-postgresql.yaml \
  -i inventory/development/hosts.yaml \
  -e "postgresql_image_tag=18.1"
```

### 5. Verify Deployment

```bash
# Check deployment
ansible-playbook playbooks/verify-deployment.yaml \
  -i inventory/development/hosts.yaml

# Or manually with kubectl
kubectl get all -n database
kubectl get pods -n database -w
```

## 📚 Playbooks

### deploy-postgresql.yaml

Main deployment playbook:

```yaml
---
- name: Deploy PostgreSQL with pgAdmin to Kubernetes
  hosts: localhost
  connection: local
  gather_facts: false
  
  vars_files:
    - ../vars/common.yaml
    - ../vars/{{ environment }}.yaml
  
  tasks:
    - name: Create namespace
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Namespace
          metadata:
            name: "{{ k8s_namespace }}"
            labels:
              name: "{{ k8s_namespace }}"
              environment: "{{ environment }}"
    
    - name: Create registry secret
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Secret
          metadata:
            name: registry-secret
            namespace: "{{ k8s_namespace }}"
          type: kubernetes.io/dockerconfigjson
          data:
            .dockerconfigjson: "{{ registry_auth | b64encode }}"
      when: registry_auth is defined
    
    - name: Deploy PostgreSQL secrets
      kubernetes.core.k8s:
        state: present
        template: ../templates/secrets.yaml.j2
        namespace: "{{ k8s_namespace }}"
      no_log: true
    
    - name: Deploy PostgreSQL ConfigMap
      kubernetes.core.k8s:
        state: present
        template: ../templates/configmap.yaml.j2
        namespace: "{{ k8s_namespace }}"
    
    - name: Deploy Persistent Volume Claim
      kubernetes.core.k8s:
        state: present
        template: ../templates/pvc.yaml.j2
        namespace: "{{ k8s_namespace }}"
    
    - name: Deploy StatefulSet
      kubernetes.core.k8s:
        state: present
        template: ../templates/statefulset.yaml.j2
        namespace: "{{ k8s_namespace }}"
    
    - name: Deploy Services
      kubernetes.core.k8s:
        state: present
        template: ../templates/services.yaml.j2
        namespace: "{{ k8s_namespace }}"
    
    - name: Deploy Ingress
      kubernetes.core.k8s:
        state: present
        template: ../templates/ingress.yaml.j2
        namespace: "{{ k8s_namespace }}"
      when: ingress_enabled | default(false)
    
    - name: Wait for StatefulSet to be ready
      kubernetes.core.k8s_info:
        kind: StatefulSet
        name: postgresql
        namespace: "{{ k8s_namespace }}"
        wait: yes
        wait_condition:
          type: Ready
          status: "True"
        wait_timeout: 600
    
    - name: Get PostgreSQL pod name
      kubernetes.core.k8s_info:
        kind: Pod
        namespace: "{{ k8s_namespace }}"
        label_selectors:
          - app=postgresql
      register: postgresql_pods
    
    - name: Display access information
      debug:
        msg:
          - "PostgreSQL deployment completed successfully!"
          - "Namespace: {{ k8s_namespace }}"
          - "Pod: {{ postgresql_pods.resources[0].metadata.name }}"
          - "PostgreSQL service: postgresql.{{ k8s_namespace }}.svc.cluster.local:5432"
          - "pgAdmin service: pgadmin.{{ k8s_namespace }}.svc.cluster.local:8080"
          - "To access pgAdmin: kubectl port-forward -n {{ k8s_namespace }} {{ postgresql_pods.resources[0].metadata.name }} 8080:8080"
```

**Usage:**

```bash
# Development
ansible-playbook playbooks/deploy-postgresql.yaml \
  -i inventory/development/hosts.yaml \
  -e "environment=development"

# Production
ansible-playbook playbooks/deploy-postgresql.yaml \
  -i inventory/production/hosts.yaml \
  -e "environment=production" \
  --vault-password-file .vault_pass
```

### undeploy-postgresql.yaml

Remove deployment:

```yaml
---
- name: Undeploy PostgreSQL from Kubernetes
  hosts: localhost
  connection: local
  gather_facts: false
  
  vars_files:
    - ../vars/common.yaml
    - ../vars/{{ environment }}.yaml
  
  tasks:
    - name: Confirm undeploy
      pause:
        prompt: "Are you sure you want to undeploy PostgreSQL from {{ k8s_namespace }}? (yes/no)"
      register: confirm
    
    - name: Abort if not confirmed
      fail:
        msg: "Undeploy cancelled by user"
      when: confirm.user_input != "yes"
    
    - name: Remove Ingress
      kubernetes.core.k8s:
        state: absent
        kind: Ingress
        name: pgadmin
        namespace: "{{ k8s_namespace }}"
    
    - name: Remove Services
      kubernetes.core.k8s:
        state: absent
        kind: Service
        name: "{{ item }}"
        namespace: "{{ k8s_namespace }}"
      loop:
        - postgresql
        - pgadmin
    
    - name: Remove StatefulSet
      kubernetes.core.k8s:
        state: absent
        kind: StatefulSet
        name: postgresql
        namespace: "{{ k8s_namespace }}"
    
    - name: Remove ConfigMap
      kubernetes.core.k8s:
        state: absent
        kind: ConfigMap
        name: postgresql-config
        namespace: "{{ k8s_namespace }}"
    
    - name: Remove Secrets
      kubernetes.core.k8s:
        state: absent
        kind: Secret
        name: postgresql-secret
        namespace: "{{ k8s_namespace }}"
      no_log: true
    
    - name: Remove PVC (optional - keeps data by default)
      kubernetes.core.k8s:
        state: absent
        kind: PersistentVolumeClaim
        name: postgres-data
        namespace: "{{ k8s_namespace }}"
      when: remove_pvc | default(false)
    
    - name: Remove namespace (optional)
      kubernetes.core.k8s:
        state: absent
        kind: Namespace
        name: "{{ k8s_namespace }}"
      when: remove_namespace | default(false)
    
    - name: Display completion message
      debug:
        msg:
          - "PostgreSQL undeployed successfully!"
          - "Note: PVC was {{ 'removed' if remove_pvc | default(false) else 'preserved' }}"
```

**Usage:**

```bash
# Remove deployment (keep PVC)
ansible-playbook playbooks/undeploy-postgresql.yaml \
  -i inventory/development/hosts.yaml \
  -e "environment=development"

# Remove everything including data
ansible-playbook playbooks/undeploy-postgresql.yaml \
  -i inventory/development/hosts.yaml \
  -e "environment=development" \
  -e "remove_pvc=true"
```

### update-images.yaml

Update container images:

```yaml
---
- name: Update PostgreSQL container images
  hosts: localhost
  connection: local
  gather_facts: false
  
  vars_files:
    - ../vars/common.yaml
    - ../vars/{{ environment }}.yaml
  
  tasks:
    - name: Update StatefulSet images
      kubernetes.core.k8s:
        state: patched
        kind: StatefulSet
        name: postgresql
        namespace: "{{ k8s_namespace }}"
        definition:
          spec:
            template:
              spec:
                containers:
                  - name: postgresql
                    image: "{{ postgresql_image_registry }}/{{ postgresql_image_repository }}:{{ postgresql_image_tag }}"
                  - name: pgadmin4
                    image: "{{ pgadmin_image_registry }}/{{ pgadmin_image_repository }}:{{ pgadmin_image_tag }}"
    
    - name: Wait for rollout to complete
      kubernetes.core.k8s_info:
        kind: StatefulSet
        name: postgresql
        namespace: "{{ k8s_namespace }}"
        wait: yes
        wait_condition:
          type: Ready
          status: "True"
        wait_timeout: 600
    
    - name: Get updated pod information
      kubernetes.core.k8s_info:
        kind: Pod
        namespace: "{{ k8s_namespace }}"
        label_selectors:
          - app=postgresql
      register: pods
    
    - name: Display update status
      debug:
        msg:
          - "Images updated successfully!"
          - "PostgreSQL: {{ postgresql_image_registry }}/{{ postgresql_image_repository }}:{{ postgresql_image_tag }}"
          - "pgAdmin: {{ pgadmin_image_registry }}/{{ pgadmin_image_repository }}:{{ pgadmin_image_tag }}"
```

**Usage:**

```bash
ansible-playbook playbooks/update-images.yaml \
  -i inventory/production/hosts.yaml \
  -e "environment=production" \
  -e "postgresql_image_tag=18.1"
```

### backup-database.yaml

Backup PostgreSQL database:

```yaml
---
- name: Backup PostgreSQL database
  hosts: localhost
  connection: local
  gather_facts: false
  
  vars_files:
    - ../vars/common.yaml
    - ../vars/{{ environment }}.yaml
  
  vars:
    backup_timestamp: "{{ ansible_date_time.iso8601_basic_short }}"
    backup_path: "/tmp/postgres-backup-{{ backup_timestamp }}.sql"
  
  tasks:
    - name: Get PostgreSQL pod name
      kubernetes.core.k8s_info:
        kind: Pod
        namespace: "{{ k8s_namespace }}"
        label_selectors:
          - app=postgresql
      register: pods
    
    - name: Create backup
      kubernetes.core.k8s_exec:
        namespace: "{{ k8s_namespace }}"
        pod: "{{ pods.resources[0].metadata.name }}"
        container: postgresql
        command: pg_dumpall -U postgres
      register: backup_output
    
    - name: Save backup to file
      copy:
        content: "{{ backup_output.stdout }}"
        dest: "{{ backup_path }}"
        mode: '0600'
    
    - name: Display backup information
      debug:
        msg:
          - "Backup completed successfully!"
          - "Backup file: {{ backup_path }}"
          - "Size: {{ (backup_output.stdout | length / 1024 / 1024) | round(2) }} MB"
```

**Usage:**

```bash
ansible-playbook playbooks/backup-database.yaml \
  -i inventory/production/hosts.yaml \
  -e "environment=production"
```

## ⚙️ Variables

### Common Variables (vars/common.yaml)

```yaml
---
# Kubernetes configuration
k8s_namespace: database
k8s_wait_timeout: 600

# PostgreSQL configuration
postgres_database: postgres
postgres_user: postgres
postgres_data_dir: /var/lib/postgresql/data/pgdata

# pgAdmin configuration
pgadmin_listen_address: 0.0.0.0
pgadmin_listen_port: 8080

# Service configuration
postgresql_service_port: 5432
pgadmin_service_port: 8080

# Security
run_as_user: 1001
fs_group: 1001
```

### Environment-Specific Variables

**vars/development.yaml:**

```yaml
---
environment: development

# Image configuration
postgresql_image_registry: registry.example.com
postgresql_image_repository: postgresql
postgresql_image_tag: "18-dev"
postgresql_image_pull_policy: Always

pgadmin_image_registry: registry.example.com
pgadmin_image_repository: pgadmin
pgadmin_image_tag: latest
pgadmin_image_pull_policy: Always

# Resource limits (smaller for dev)
postgresql_resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"

pgadmin_resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "250m"

# Storage
storage_class: standard
storage_size: 5Gi

# Ingress
ingress_enabled: true
ingress_class: nginx
ingress_host: pgadmin-dev.example.com
ingress_tls_enabled: false
```

**vars/production.yaml:**

```yaml
---
environment: production

# Image configuration (with digests for immutability)
postgresql_image_registry: registry.example.com
postgresql_image_repository: postgresql
postgresql_image_tag: "18"
postgresql_image_digest: "sha256:abc123..."
postgresql_image_pull_policy: IfNotPresent

pgadmin_image_registry: registry.example.com
pgadmin_image_repository: pgadmin
pgadmin_image_tag: "9.11"
pgadmin_image_digest: "sha256:def456..."
pgadmin_image_pull_policy: IfNotPresent

# Resource limits (larger for production)
postgresql_resources:
  requests:
    memory: "4Gi"
    cpu: "2000m"
  limits:
    memory: "8Gi"
    cpu: "4000m"

pgadmin_resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

# Storage
storage_class: fast-ssd
storage_size: 100Gi

# Ingress
ingress_enabled: true
ingress_class: nginx
ingress_host: pgadmin.example.com
ingress_tls_enabled: true
ingress_tls_secret: pgadmin-tls-cert
ingress_annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
  nginx.ingress.kubernetes.io/ssl-redirect: "true"

# Monitoring and backup
monitoring_enabled: true
backup_enabled: true
```

## 📦 Inventory

### Development Inventory

**inventory/development/hosts.yaml:**

```yaml
---
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_python_interpreter: /usr/bin/python3
```

**inventory/development/group_vars/all.yaml:**

```yaml
---
k8s_context: dev-cluster
k8s_namespace: database-dev

postgres_password: "dev-password"
pgadmin_email: "admin@dev.example.com"
pgadmin_password: "dev-pgadmin-pass"
```

### Production Inventory

**inventory/production/hosts.yaml:**

```yaml
---
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_python_interpreter: /usr/bin/python3
```

**inventory/production/group_vars/all.yaml:**

```yaml
---
k8s_context: prod-cluster
k8s_namespace: database

# Use vault variables
postgres_password: "{{ vault_postgres_password }}"
pgadmin_email: "{{ vault_pgadmin_email }}"
pgadmin_password: "{{ vault_pgadmin_password }}"
```

**inventory/production/group_vars/vault.yaml (encrypted):**

```bash
# Create with:
ansible-vault create inventory/production/group_vars/vault.yaml

# Contents:
vault_postgres_password: "secure-production-password"
vault_pgadmin_email: "admin@production.example.com"
vault_pgadmin_password: "secure-pgadmin-password"
```

## 🔧 Advanced Usage

### Ansible Roles

Organize as roles for better reusability:

```
ansible/
└── roles/
    └── postgresql/
        ├── tasks/
        │   ├── main.yaml
        │   ├── namespace.yaml
        │   ├── secrets.yaml
        │   └── deploy.yaml
        ├── templates/
        │   ├── statefulset.yaml.j2
        │   └── services.yaml.j2
        ├── defaults/
        │   └── main.yaml
        └── vars/
            └── main.yaml
```

**playbook with role:**

```yaml
---
- name: Deploy PostgreSQL
  hosts: localhost
  roles:
    - postgresql
```

### Tags

Use tags for selective execution:

```yaml
tasks:
  - name: Deploy namespace
    kubernetes.core.k8s:
      # ...
    tags:
      - namespace
      - deploy
  
  - name: Deploy StatefulSet
    kubernetes.core.k8s:
      # ...
    tags:
      - statefulset
      - deploy
```

**Run specific tags:**

```bash
# Only deploy namespace
ansible-playbook playbooks/deploy-postgresql.yaml --tags namespace

# Skip statefulset
ansible-playbook playbooks/deploy-postgresql.yaml --skip-tags statefulset
```

### Handlers

Use handlers for conditional actions:

```yaml
tasks:
  - name: Update ConfigMap
    kubernetes.core.k8s:
      # ...
    notify: restart postgresql

handlers:
  - name: restart postgresql
    kubernetes.core.k8s:
      state: absent
      kind: Pod
      name: postgresql-0
      namespace: "{{ k8s_namespace }}"
```

### CI/CD Integration

**GitLab CI example:**

```yaml
deploy_dev:
  stage: deploy
  script:
    - ansible-playbook playbooks/deploy-postgresql.yaml
        -i inventory/development/hosts.yaml
        -e "environment=development"
  only:
    - develop

deploy_prod:
  stage: deploy
  script:
    - ansible-playbook playbooks/deploy-postgresql.yaml
        -i inventory/production/hosts.yaml
        -e "environment=production"
        --vault-password-file $VAULT_PASSWORD_FILE
  only:
    - main
  when: manual
```

## 🐛 Troubleshooting

### Collection Not Found

```bash
# Install required collections
ansible-galaxy collection install -r requirements.yaml

# Or manually
ansible-galaxy collection install kubernetes.core
```

### kubectl Not Configured

```bash
# Verify kubectl works
kubectl cluster-info

# Check kubeconfig
echo $KUBECONFIG
cat ~/.kube/config
```

### Permission Denied

```bash
# Check kubectl permissions
kubectl auth can-i create pods --namespace database

# Ensure proper service account/RBAC
```

### Vault Errors

```bash
# Verify vault password
ansible-vault view inventory/production/group_vars/vault.yaml \
  --vault-password-file .vault_pass

# Re-encrypt if needed
ansible-vault rekey inventory/production/group_vars/vault.yaml
```

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [kubernetes.core Collection](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

## 🎯 Next Steps

- Set up Ansible Tower/AWX for GUI management
- Implement dynamic inventory
- Create custom Ansible modules
- Add monitoring playbooks
- Automate backup/restore schedules

---

**Need help?** Open an issue on GitHub or consult the [main README](../README.md).
