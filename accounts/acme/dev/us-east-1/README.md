# ACME Dev Environment - US East 1

This directory contains the Terraform configuration for the ACME development environment in US East 1, organized by team responsibilities.

## 📁 Directory Structure

```
accounts/acme/dev/us-east-1/
├── infrastructure/           # Infrastructure Team
│   ├── vpc/                 # VPC, Subnets, NAT Gateway
│   ├── ecs/                 # ECS Fargate Cluster
│   └── eks/                 # EKS Cluster
└── services/                # Services Team
    └── web/                 # Web Service (Nginx)
```

## 🏗️ Infrastructure Team

The infrastructure team manages the foundational AWS resources that are shared across all applications.

### VPC (`infrastructure/vpc/`)
- **VPC**: `acme-dev-vpc` (10.0.0.0/16)
- **Public Subnets**: 2 subnets across us-east-1a and us-east-1b
- **Private Subnets**: 2 subnets across us-east-1a and us-east-1b
- **NAT Gateway**: Single NAT gateway for cost optimization
- **Internet Gateway**: For public internet access

### ECS Cluster (`infrastructure/ecs/`)
- **Cluster**: `acme-dev-cluster`
- **Capacity Providers**: FARGATE_SPOT (cost-optimized for dev)
- **IAM Roles**: Task execution and task roles
- **Container Insights**: Enabled for monitoring

## 🚀 Applications Team

The applications team manages the deployment and configuration of individual applications.

### Web Service (`services/web/`)
- **Service**: `web-service`
- **Container**: nginx:alpine
- **ALB**: Individual ALB for the web service
- **Security Groups**: Application-specific security groups
- **Auto-scaling**: Balanced profile (1-4 instances)
- **Monitoring**: Standard observability profile

## 🚀 Deployment Instructions

### 1. Deploy Infrastructure (Infrastructure Team)
```bash
# Deploy VPC first
cd infrastructure/vpc
terragrunt plan
terragrunt apply

# Deploy ECS cluster
cd ../ecs
terragrunt plan
terragrunt apply
```

### 2. Deploy Applications (Applications Team)
```bash
# Deploy web service
cd services/web
terragrunt plan
terragrunt apply
```

## 🔗 Dependencies

```
infrastructure/vpc/ → infrastructure/ecs/ → services/web/
```

## 🏷️ Resource Naming Convention

- **Infrastructure**: `acme-dev-*` (e.g., `acme-dev-vpc`, `acme-dev-cluster`)
- **Applications**: `{app-name}-*` (e.g., `web-service`, `web-alb`)

## 🔒 Security

- **ALB Security Group**: Allows HTTP (80) and HTTPS (443) from internet
- **Tasks Security Group**: Allows traffic only from ALB
- **Private Subnets**: ECS tasks run in private subnets without public IPs
- **NAT Gateway**: Provides outbound internet access for tasks

## 📊 Monitoring

- **CloudWatch Container Insights**: Enabled on cluster
- **Application Dashboard**: Individual dashboard for web service
- **Auto-scaling Alarms**: CPU and memory-based scaling

## 💰 Cost Optimization

- **FARGATE_SPOT**: Used for cost savings in development
- **Single NAT Gateway**: Reduces NAT gateway costs
- **Balanced Auto-scaling**: Prevents over-provisioning
