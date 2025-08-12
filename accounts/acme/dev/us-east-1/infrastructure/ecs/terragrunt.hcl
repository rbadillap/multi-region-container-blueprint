include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../../modules/ecs/cluster"
}

# Dependency on VPC for networking resources (subnets, security groups)
dependency "networking" {
  config_path = "../vpc"
}

inputs = {
  # ECS cluster name - will be used for service discovery and resource naming
  cluster_name = "acme-dev-cluster"
  
  # Capacity provider strategy: cost-optimized uses FARGATE_SPOT for ~70% cost savings
  # Suitable for development environments where availability is less critical
  strategy_profile = "cost-optimized"
  
  tags = {
    Component   = "compute"
    Environment = "dev"
    ManagedBy   = "terragrunt"
  }
}
