# Comoda Infra (Terraform)

Terraform IaC for the Comoda ecosystem on GCP. This project provisions Cloud Run services, Cloud Storage, Cloud SQL (Postgres), BigQuery datasets, Cloud Scheduler jobs, IAM service accounts, and optional Pub/Sub. It is organized into modular, per-service stacks with reusable modules.

## Structure

```
infra/
  cloud_run/           # Cloud Run services for backend, ml, backfill
  cloud_storage/       # GCS buckets for models, backfill, artifacts
  cloud_sql/           # Cloud SQL Postgres instance and databases
  bigquery/            # Optional analytics/model metrics datasets
  cloud_scheduler/     # Scheduled jobs for ingestion/retrain/scoring/backfill
  iam/                 # Service accounts and role bindings
  modules/             # Reusable Terraform modules
  scripts/             # Helper scripts (env + secrets)
  .github/workflows/   # GitHub Actions CI for Terraform
```

## Prereqs

- Terraform >= 1.6
- GCP project with billing enabled
- Permissions to create resources (Owner or equivalent granular roles)
- Artifact Registry (for images referenced by Cloud Run)

## Usage

Each subfolder is an independent Terraform stack. Init, plan, and apply them in a sensible order. Recommended order:

1. iam/
2. cloud_storage/
3. bigquery/ (optional)
4. cloud_sql/
5. cloud_run/
6. cloud_scheduler/

Example:

```
cd infra/iam
terraform init
terraform apply -auto-approve -var="project_id=comoda" -var="region=us-central1" -var="location=US"

# Then provision storage
cd ../cloud_storage
terraform init
terraform apply -auto-approve -var="project_id=comoda" -var="region=us-central1" -var="location=US"

# (Optional) BigQuery dataset
cd ../bigquery
terraform init
terraform apply -auto-approve -var="project_id=comoda" -var="region=us-central1" -var="location=US" -var="analytics_dataset=comoda_analytics"

# Cloud SQL
cd ../cloud_sql
terraform init
terraform apply -auto-approve -var="project_id=comoda" -var="region=us-central1" -var="location=US"

# Cloud Run (provide built images and SA emails from IAM outputs)
cd ../cloud_run
terraform init
terraform apply -auto-approve \
  -var="project_id=comoda" -var="region=us-central1" -var="location=US" \
  -var="backend_image=us-central1-docker.pkg.dev/comoda/artifacts/backend:latest" \
  -var="ml_image=us-central1-docker.pkg.dev/comoda/artifacts/ml:latest" \
  -var="backfill_image=us-central1-docker.pkg.dev/comoda/artifacts/backfill:latest" \
  -var="backend_sa_email=$(terraform -chdir=../iam output -raw backend_sa_email)" \
  -var="ml_sa_email=$(terraform -chdir=../iam output -raw ml_sa_email)" \
  -var="backfill_sa_email=$(terraform -chdir=../iam output -raw backfill_sa_email)" \
  -var="gcs_model_bucket=$(terraform -chdir=../cloud_storage output -json | jq -r .buckets.value.models)" \
  -var="bq_dataset=comoda_analytics"

# Cloud Scheduler (wire to service URLs from Cloud Run outputs)
cd ../cloud_scheduler
terraform init
terraform apply -auto-approve \
  -var="project_id=comoda" -var="region=us-central1" -var="location=US" \
  -var="backend_url=$(terraform -chdir=../cloud_run output -json service_urls | jq -r .backend)" \
  -var="ml_url=$(terraform -chdir=../cloud_run output -json service_urls | jq -r .ml)" \
  -var="backfill_url=$(terraform -chdir=../cloud_run output -json service_urls | jq -r .backfill)"
```

## Variables

Common variables (present across stacks):
- project_id (string) — GCP project ID
- region (string) — default region (e.g., us-central1)
- location (string) — multi-region/region for storage/BQ (e.g., US)

Each stack also exposes service-specific variables (see the `variables.tf` in each folder).

## Outputs

Stacks export identifiers like service URLs, bucket names, SQL connection names, service account emails, and scheduler job IDs.

## CI/CD

- `.github/workflows/terraform.yml` runs Terraform fmt/validate/plan/apply on PRs and main branch.
- Authentication: configure Workload Identity Federation or a service account key secret.

Repository secrets/variables expected by the workflow:
- Secrets
  - `GCP_PROJECT_ID`: target GCP project
  - `GCP_WORKLOAD_IDENTITY_PROVIDER`: full resource name of WIF provider
  - `GCP_TERRAFORM_SA`: service account email to impersonate
- Variables
  - `GCP_REGION`: e.g., `us-central1`
  - `GCP_LOCATION`: e.g., `US`
  - `BACKEND_IMAGE`, `ML_IMAGE`, `BACKFILL_IMAGE`: Artifact Registry image refs

## Security

- One service account per service (backend, ml, backfill).
- Least-privilege role bindings.
- Secrets referenced via Secret Manager (module provided).

## Monitoring

- Cloud Run services have logging enabled by default.
- Placeholders for alerting are included where relevant (commented).

## Notes

- Naming: resources are named `comoda-<service>-<env>` patterns; adjust via variables.
- You can extend modules under `modules/` for new services or resources.

1. **Follow Naming Conventions**: Use consistent naming for resources
2. **Document Changes**: Update this README for significant changes
3. **Test Changes**: Always run `terraform plan` before applying
4. **Security Review**: Ensure new resources follow security best practices
5. **Cost Impact**: Consider the cost implications of new resources

## Support

For issues related to this infrastructure:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review GCP documentation for specific services
3. Check Terraform documentation for configuration issues
4. Consult the team for project-specific questions

## License

This infrastructure code is part of the Comoda project. Please refer to the main project license for usage terms.

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