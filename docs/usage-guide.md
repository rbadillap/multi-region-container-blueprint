# MRCB Usage Guide

This guide provides step-by-step instructions for using the Multi-Region Container Blueprint (MRCB).

> **Note**: This project uses the modern Terragrunt pattern with `root.hcl` as the root configuration file, following the latest best practices from the Terragrunt team.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Deployment Workflows](#deployment-workflows)
4. [Configuration Management](#configuration-management)
5. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
6. [Advanced Usage](#advanced-usage)

## 🛠 Prerequisites

### Terragrunt Configuration Pattern

This project follows the modern Terragrunt best practices:

- **Root Configuration**: Uses `root.hcl` instead of the legacy `terragrunt.hcl` pattern
- **Child Configurations**: Each component has its own `terragrunt.hcl` file that includes the root configuration
- **Explicit References**: Child configurations explicitly reference `root.hcl` using `find_in_parent_folders("root.hcl")`

Example child configuration:
```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/networking"
}

inputs = {
  # Component-specific inputs
}
```

### Required Tools

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Install Terraform
brew install terraform

# Install Terragrunt
brew install terragrunt

# Install kubectl
brew install kubectl

# Verify installations
aws --version
terraform --version
terragrunt --version
kubectl version --client
```

### AWS Configuration

```bash
# Configure AWS CLI
aws configure

# Set your AWS credentials
AWS Access Key ID: [YOUR_ACCESS_KEY]
AWS Secret Access Key: [YOUR_SECRET_KEY]
Default region name: us-east-1
Default output format: json

# Verify configuration
aws sts get-caller-identity
```

## 🚀 Initial Setup

### Step 1: Create Infrastructure for State Management

Before deploying any infrastructure, you need to create S3 buckets and DynamoDB tables for state management.

```bash
# Create S3 bucket for state files
aws s3 mb s3://mrcb-terraform-state-client-a-dev --region us-east-1

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket mrcb-terraform-state-client-a-dev \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name mrcb-terraform-locks-client-a-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Verify table creation
aws dynamodb describe-table \
  --table-name mrcb-terraform-locks-client-a-dev \
  --region us-east-1
```

### Step 2: Deploy Networking Infrastructure

Networking must be deployed first as it provides the foundation for ECS and EKS.

```bash
# Navigate to networking directory
cd live/client-a/dev/us-east-1/networking

# Initialize Terragrunt
terragrunt init

# Review the plan
terragrunt plan

# Apply the configuration
terragrunt apply

# Verify outputs
terragrunt output
```

Expected outputs:
- `vpc_id`: VPC identifier
- `public_subnet_ids`: List of public subnet IDs
- `private_subnet_ids`: List of private subnet IDs

### Step 3: Deploy ECS Infrastructure

```bash
# Navigate to ECS directory
cd ../ecs

# Initialize Terragrunt
terragrunt init

# Review the plan
terragrunt plan

# Apply the configuration
terragrunt apply

# Verify outputs
terragrunt output
```

Expected outputs:
- `ecs_cluster_name`: ECS cluster name
- `alb_dns_name`: Application Load Balancer DNS name
- `ecs_service_name`: ECS service name

### Step 4: Deploy EKS Infrastructure

```bash
# Navigate to EKS directory
cd ../eks

# Initialize Terragrunt
terragrunt init

# Review the plan
terragrunt plan

# Apply the configuration
terragrunt apply

# Verify outputs
terragrunt output
```

Expected outputs:
- `cluster_name`: EKS cluster name
- `cluster_endpoint`: EKS control plane endpoint
- `kubeconfig`: Kubeconfig for kubectl access

## 🔄 Deployment Workflows

### Single Region Deployment

```bash
# Complete deployment for one region
cd live/client-a/dev/us-east-1

# Deploy in order: networking → ecs → eks
cd networking && terragrunt apply
cd ../ecs && terragrunt apply
cd ../eks && terragrunt apply
```

### Multi-Region Deployment

```bash
# Deploy networking to both regions
cd live/client-a/dev/us-east-1/networking && terragrunt apply
cd ../../eu-west-1/networking && terragrunt apply

# Deploy ECS to both regions
cd ../../us-east-1/ecs && terragrunt apply
cd ../../eu-west-1/ecs && terragrunt apply

# Deploy EKS to both regions
cd ../../us-east-1/eks && terragrunt apply
cd ../../eu-west-1/eks && terragrunt apply
```

### Production Deployment

```bash
# Deploy to production (adjust resource sizes)
cd live/client-a/prod/us-east-1

# Deploy networking with production settings
cd networking && terragrunt apply

# Deploy ECS with production settings
cd ../ecs && terragrunt apply

# Deploy EKS with production settings
cd ../eks && terragrunt apply
```

## ⚙️ Configuration Management

### Environment-Specific Configuration

Each environment can have different configurations:

```hcl
# Development environment (live/client-a/dev/us-east-1/ecs/terragrunt.hcl)
inputs = {
  service_desired_count = 2
  task_cpu = 256
  task_memory = 512
  enable_autoscaling = true
}

# Production environment (live/client-a/prod/us-east-1/ecs/terragrunt.hcl)
inputs = {
  service_desired_count = 4
  task_cpu = 512
  task_memory = 1024
  enable_autoscaling = true
}
```

### Customizing Container Images

```hcl
# Update container image
inputs = {
  container_image = "your-registry/your-app:latest"
  container_environment = [
    {
      name  = "ENVIRONMENT"
      value = "production"
    },
    {
      name  = "API_URL"
      value = "https://api.example.com"
    }
  ]
}
```

### Scaling Configuration

```hcl
# ECS scaling
inputs = {
  service_min_count = 2
  service_max_count = 10
  autoscaling_cpu_target = 70
}

# EKS scaling
inputs = {
  node_group_min_size = 2
  node_group_max_size = 6
  node_group_instance_types = ["t3.large"]
}
```

## 📊 Monitoring and Troubleshooting

### ECS Monitoring

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster client-a-dev-ecs \
  --services client-a-dev-ecs-service \
  --region us-east-1

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/client-a-dev-ecs"

# Check ALB health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

### EKS Monitoring

```bash
# Get cluster info
aws eks describe-cluster \
  --name client-a-dev-eks \
  --region us-east-1

# Check node group status
aws eks describe-nodegroup \
  --cluster-name client-a-dev-eks \
  --nodegroup-name client-a-dev-eks-node-group \
  --region us-east-1

# Access cluster with kubectl
aws eks update-kubeconfig --name client-a-dev-eks --region us-east-1
kubectl get nodes
kubectl get pods --all-namespaces
```

### Common Issues and Solutions

#### State Lock Issues

```bash
# Check DynamoDB table
aws dynamodb describe-table \
  --table-name mrcb-terraform-locks-client-a-dev

# Force unlock (use with caution)
terragrunt force-unlock <lock-id>
```

#### S3 Access Issues

```bash
# Verify bucket exists
aws s3 ls s3://mrcb-terraform-state-client-a-dev

# Check bucket policy
aws s3api get-bucket-policy \
  --bucket mrcb-terraform-state-client-a-dev
```

#### EKS Access Issues

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --name client-a-dev-eks \
  --region us-east-1

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

## 🔧 Advanced Usage

### Adding a New Client

1. **Create directory structure:**
   ```bash
   mkdir -p live/client-b/{dev,prod}/{us-east-1,eu-west-1}/{networking,ecs,eks}
   ```

2. **Copy and modify terragrunt.hcl files:**
   ```bash
   cp live/client-a/dev/us-east-1/networking/terragrunt.hcl \
      live/client-b/dev/us-east-1/networking/terragrunt.hcl
   ```

3. **Update client-specific values:**
   ```hcl
   locals {
     name_prefix = "client-b-dev"  # Update this
   }
   ```

4. **Create state management infrastructure:**
   ```bash
   aws s3 mb s3://mrcb-terraform-state-client-b-dev --region us-east-1
   aws dynamodb create-table \
     --table-name mrcb-terraform-locks-client-b-dev \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

### Adding a New Region

1. **Create region directory structure:**
   ```bash
   mkdir -p live/client-a/dev/us-west-2/{networking,ecs,eks}
   ```

2. **Update region-specific configurations:**
   ```hcl
   locals {
     region = "us-west-2"
     availability_zones = ["us-west-2a", "us-west-2b"]
     public_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
     private_subnet_cidrs = ["10.0.12.0/24", "10.0.13.0/24"]
   }
   ```

3. **Deploy in order:**
   ```bash
   cd live/client-a/dev/us-west-2/networking && terragrunt apply
   cd ../ecs && terragrunt apply
   cd ../eks && terragrunt apply
   ```

### Custom Module Development

1. **Create a new module:**
   ```bash
   mkdir -p modules/rds
   touch modules/rds/{main.tf,variables.tf,outputs.tf}
   ```

2. **Reference the module in terragrunt.hcl:**
   ```hcl
   terraform {
     source = "../../../../../modules/rds"
   }
   ```

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      
      - name: Deploy Networking
        run: |
          cd live/client-a/dev/us-east-1/networking
          terragrunt init
          terragrunt apply -auto-approve
      
      - name: Deploy ECS
        run: |
          cd live/client-a/dev/us-east-1/ecs
          terragrunt init
          terragrunt apply -auto-approve
      
      - name: Deploy EKS
        run: |
          cd live/client-a/dev/us-east-1/eks
          terragrunt init
          terragrunt apply -auto-approve
```

## 🧹 Cleanup

### Destroy Infrastructure

```bash
# Destroy in reverse order: eks → ecs → networking
cd live/client-a/dev/us-east-1/eks && terragrunt destroy
cd ../ecs && terragrunt destroy
cd ../networking && terragrunt destroy
```

### Clean Up State Management

```bash
# Delete S3 bucket (must be empty first)
aws s3 rm s3://mrcb-terraform-state-client-a-dev --recursive
aws s3 rb s3://mrcb-terraform-state-client-a-dev

# Delete DynamoDB table
aws dynamodb delete-table \
  --table-name mrcb-terraform-locks-client-a-dev \
  --region us-east-1
```

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)

---

For additional support, contact: info@rbadillap.dev 