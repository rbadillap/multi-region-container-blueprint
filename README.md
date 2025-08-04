# Multi-Region Container Blueprint (MRCB)

> Production-grade infrastructure blueprint to deploy **ECS with Fargate** and **EKS** across **multiple AWS regions**, using **Terragrunt + Terraform** following best practices and minimal configuration.

> **Note**: This project uses the modern Terragrunt pattern with `root.hcl` as the root configuration file, following the latest best practices from the Terragrunt team.

## 🎯 What is MRCB?

MRCB is a reusable and well-structured Terragrunt/Terraform project that enables deploying:
- Amazon ECS (with Fargate) services
- Amazon EKS clusters
- Across multiple clients and environments (dev/prod) in different regions
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
mrcb/
├── live/                       # Terragrunt configurations per client/env/region
│   └── client-a/
│       ├── dev/
│       │   ├── us-east-1/
│       │   │   ├── networking/
│       │   │   ├── ecs/
│       │   │   └── eks/
│       │   └── eu-west-1/
│       │       ├── networking/
│       │       ├── ecs/
│       │       └── eks/
│       └── prod/
│           ├── us-east-1/
│           │   ├── networking/
│           │   ├── ecs/
│           │   └── eks/
│           └── eu-west-1/
│               ├── networking/
│               ├── ecs/
│               └── eks/
├── modules/                   # Reusable Terraform modules
│   ├── networking/            # VPC, subnets, route tables, NAT, IGW
│   ├── ecs-fargate/           # ECS Cluster, Task Definition, ALB, Service
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
   # Create S3 bucket for state files
   aws s3 mb s3://mrcb-terraform-state-client-a-dev --region us-east-1
   
   # Create DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name mrcb-terraform-locks-client-a-dev \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

2. **Deploy infrastructure:**
   ```bash
   # Deploy networking
   cd live/client-a/dev/us-east-1/networking
   terragrunt init && terragrunt apply
   
   # Deploy ECS
   cd ../ecs
   terragrunt init && terragrunt apply
   
   # Deploy EKS
   cd ../eks
   terragrunt init && terragrunt apply
   ```

## 📚 Documentation

- **[Complete Usage Guide](docs/usage-guide.md)** - Step-by-step deployment instructions, configuration examples, troubleshooting, and advanced usage
- **[Technical Scope](TECHNICAL-SCOPE.md)** - Detailed technical specifications and requirements

## 🔧 Key Features

- **Multi-Region Support**: Deploy to multiple AWS regions with consistent configuration
- **Multi-Client Support**: Support multiple clients with isolated infrastructure
- **Environment Separation**: Separate dev/prod environments with different configurations
- **DRY Configuration**: Reusable modules with environment-specific customization
- **State Management**: S3 backend with DynamoDB locking for team collaboration
- **Security Best Practices**: Private subnets, security groups, IAM roles with least privilege

## 📞 Support

For support and questions:
- **Email**: info@rbadillap.dev
- **Issues**: Create an issue in the repository

---

**Built with ❤️ by Ronny Badilla** 