# Comoda Infrastructure

Infrastructure as Code (IaC) for the Comoda platform deployment and management.

## Overview

This repository contains all infrastructure configuration, deployment scripts, and DevOps tooling for the Comoda platform. It manages cloud resources, CI/CD pipelines, monitoring, and security configurations.

## Tech Stack

- **IaC Tool**: Terraform / Pulumi / AWS CDK
- **Cloud Provider**: Google Cloud Platform (GCP) / AWS / Azure
- **Container Orchestration**: Kubernetes / Google Kubernetes Engine (GKE)
- **CI/CD**: GitHub Actions / GitLab CI / Jenkins
- **Monitoring**: Prometheus + Grafana / Google Cloud Monitoring
- **Secrets Management**: Google Secret Manager / AWS Secrets Manager / HashiCorp Vault
- **Container Registry**: Google Container Registry / Docker Hub

## Project Structure

```
infra/
├── terraform/             # Terraform configurations
│   ├── modules/          # Reusable Terraform modules
│   ├── environments/     # Environment-specific configs
│   └── global/          # Global resources
├── kubernetes/           # Kubernetes manifests
│   ├── base/            # Base configurations
│   ├── overlays/        # Environment overlays
│   └── helm/            # Helm charts
├── scripts/              # Deployment and utility scripts
├── monitoring/           # Monitoring configurations
├── security/             # Security policies and configs
├── .github/             # GitHub Actions workflows
├── docker/              # Docker configurations
└── README.md            # This file
```

## Environments

- **Development**: `dev.comoda.io`
- **Staging**: `staging.comoda.io`
- **Production**: `comoda.io`

## Getting Started

### Prerequisites

- Terraform 1.5+
- kubectl
- Docker
- gcloud CLI (for GCP)
- Appropriate cloud provider credentials

### Local Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd infra
   ```

2. Install dependencies:
   ```bash
   # Install Terraform (if not already installed)
   # Install kubectl
   # Install gcloud CLI
   ```

3. Configure cloud credentials:
   ```bash
   # For GCP
   gcloud auth login
   gcloud config set project <project-id>
   
   # Set up service account key
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
   ```

4. Initialize Terraform:
   ```bash
   cd terraform/environments/dev
   terraform init
   ```

### Deployment

#### Infrastructure Deployment

1. Plan the deployment:
   ```bash
   terraform plan
   ```

2. Apply the configuration:
   ```bash
   terraform apply
   ```

#### Application Deployment

1. Build and push images:
   ```bash
   ./scripts/build-and-push.sh
   ```

2. Deploy to Kubernetes:
   ```bash
   kubectl apply -k kubernetes/overlays/dev
   ```

## Environment Variables & Secrets

Key configuration variables:

### Terraform Variables
- `project_id`: GCP project ID
- `region`: Primary deployment region
- `environment`: Environment name (dev/staging/prod)
- `cluster_name`: Kubernetes cluster name

### Required Secrets (GitHub Secrets)
- `GCP_SERVICE_ACCOUNT_KEY`: GCP service account JSON key
- `CRYPTO_API_KEY`: Cryptocurrency API access key
- `DATABASE_PASSWORD`: Database root password
- `JWT_SECRET_KEY`: JWT signing secret

## CI/CD Pipeline

The CI/CD pipeline is configured in `.github/workflows/` and includes:

1. **Infrastructure Pipeline** (`infra.yml`)
   - Terraform validation and planning
   - Infrastructure deployment
   - Security scanning

2. **Application Pipeline** (in respective repos)
   - Build and test applications
   - Build and push Docker images
   - Deploy to Kubernetes

## Monitoring & Logging

- **Metrics**: Prometheus + Grafana dashboards
- **Logs**: Google Cloud Logging / ELK Stack
- **Alerts**: Google Cloud Monitoring / PagerDuty
- **Uptime Monitoring**: Google Cloud Monitoring / Pingdom

## Security

- Network security groups and firewall rules
- Pod security policies
- RBAC configurations
- Secret encryption at rest
- TLS/SSL certificates (Let's Encrypt)

## Backup & Disaster Recovery

- Automated database backups
- Infrastructure state backup
- Cross-region replication
- Disaster recovery runbooks

## Cost Management

- Resource tagging strategy
- Cost monitoring and alerts
- Right-sizing recommendations
- Automated resource cleanup

## Troubleshooting

Common issues and solutions:

### Terraform Issues
```bash
# Reset Terraform state
terraform refresh

# Import existing resources
terraform import <resource_type>.<name> <resource_id>
```

### Kubernetes Issues
```bash
# Check cluster status
kubectl cluster-info

# Debug pod issues
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b infra/feature-name`
3. Make your changes
4. Test changes in development environment
5. Run security scans: `./scripts/security-scan.sh`
6. Commit your changes: `git commit -am 'Add infrastructure feature'`
7. Push to the branch: `git push origin infra/feature-name`
8. Create a Pull Request

## License

[License information to be added]