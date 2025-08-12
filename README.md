# Terrawork

> Production-grade infrastructure blueprint to deploy **ECS with Fargate** and **EKS** across **multiple AWS regions**, using **Terragrunt + Terraform** following best practices and minimal configuration.

> **Note**: This project uses the modern Terragrunt pattern with `root.hcl` as the root configuration file, following the latest best practices from the Terragrunt team.

## 🎯 What is Terrawork?

Terrawork is a reusable and well-structured Terragrunt/Terraform project that enables deploying:
- Amazon ECS (with Fargate) services
- Amazon EKS clusters
- Across multiple AWS accounts and environments (dev/prod) in different regions
- Using a **common, DRY, version-controlled IaC codebase**

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Multi-Region Setup                      │
├─────────────────────────────────────────────────────────────┤
│  Client A                    │  Client B                   │
│  ┌─────────────────────────┐ │  ┌─────────────────────────┐ │
│  │ Dev Environment         │ │  │ Dev Environment         │ │
│  │ ┌─────────┐ ┌─────────┐ │ │  │ ┌─────────┐ ┌─────────┐ │ │
│  │ │us-east-1│ │eu-west-1│ │ │  │ │us-east-1│ │eu-west-1│ │ │
│  │ │ ECS/EKS │ │ ECS/EKS │ │ │  │ │ ECS/EKS │ │ ECS/EKS │ │ │
│  │ └─────────┘ └─────────┘ │ │  │ └─────────┘ └─────────┘ │ │
│  └─────────────────────────┘ │  └─────────────────────────┘ │
│  ┌─────────────────────────┐ │  ┌─────────────────────────┐ │
│  │ Prod Environment        │ │  │ Prod Environment        │ │
│  │ ┌─────────┐ ┌─────────┐ │ │  │ ┌─────────┐ ┌─────────┐ │ │
│  │ │us-east-1│ │eu-west-1│ │ │  │ │us-east-1│ │eu-west-1│ │ │
│  │ │ ECS/EKS │ │ ECS/EKS │ │ │  │ │ ECS/EKS │ │ ECS/EKS │ │ │
│  │ └─────────┘ └─────────┘ │ │  │ └─────────┘ └─────────┘ │ │
│  └─────────────────────────┘ │  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
terrawork/
├── accounts/                   # Terragrunt configurations per account/env/region
│   └── acme/
│       ├── dev/
│       │   ├── us-east-1/
│       │   │   ├── infrastructure/
│       │   │   │   ├── vpc/
│       │   │   │   ├── ecs/
│       │   │   │   └── eks/
│       │   │   └── services/
│       │   │       └── web/
│       │   └── eu-west-1/
│       │       └── .gitkeep
│       └── prod/
│           ├── us-east-1/
│           │   └── .gitkeep
│           └── eu-west-1/
│               └── .gitkeep
├── modules/                   # Reusable Terraform modules
│   ├── vpc/                   # VPC, subnets, route tables, NAT, IGW
│   ├── ecs/cluster/           # ECS Cluster, Task Definition, ALB, Service
│   ├── ecs/service/           # ECS Service, Task Definition, ALB
│   └── eks/                   # EKS Cluster, NodeGroup, IAM, Outputs
├── docs/
│   └── usage-guide.md         # Complete deployment guide
├── root.hcl                   # Root configuration
└── README.md                  # This file
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0
3. **Terragrunt** >= 0.45
4. **kubectl** (for EKS access)

### Deploy Your First Environment

1. **Create state management infrastructure:**
   ```bash
   # Use the bootstrap script for secure and automated setup
   ./scripts/bootstrap.sh acme dev us-east-1
   ```

2. **Deploy infrastructure:**
   ```bash
   # Deploy VPC
   cd accounts/acme/dev/us-east-1/infrastructure/vpc
   terragrunt init && terragrunt apply
   
   # Deploy ECS cluster
   cd ../ecs
   terragrunt init && terragrunt apply
   
   # Deploy EKS cluster
   cd ../eks
   terragrunt init && terragrunt apply
   ```

## 📚 Documentation

- **[Complete Usage Guide](docs/usage-guide.md)** - Step-by-step deployment instructions, configuration examples, troubleshooting, and advanced usage

## 🔧 Key Features

- **Multi-Region Support**: Deploy to multiple AWS regions with consistent configuration
- **Multi-Account Support**: Support multiple AWS accounts with isolated infrastructure
- **Environment Separation**: Separate dev/prod environments with different configurations
- **DRY Configuration**: Reusable modules with environment-specific customization
- **Account Configuration**: Centralized account configuration with `account.hcl` files
- **State Management**: S3 backend with DynamoDB locking for team collaboration
- **Security Best Practices**: Private subnets, security groups, IAM roles with least privilege

---