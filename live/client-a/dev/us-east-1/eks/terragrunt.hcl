include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

locals {
  # Environment-specific variables
  cluster_name = "client-a-dev-eks"
  region       = "us-east-1"
}

terraform {
  source = "../../../../../modules/eks"
}

inputs = {
  cluster_name        = local.cluster_name
  kubernetes_version  = "1.28"
  vpc_id             = dependency.networking.outputs.vpc_id
  public_subnet_ids  = dependency.networking.outputs.public_subnet_ids
  private_subnet_ids = dependency.networking.outputs.private_subnet_ids
  
  # Node group configuration
  node_group_desired_size = 2
  node_group_max_size     = 4
  node_group_min_size     = 1
  node_group_instance_types = ["t3.medium"]
  
  # Optional: Enable AWS Load Balancer Controller
  enable_aws_load_balancer_controller = false
  
  tags = {
    Component = "eks"
    Region    = local.region
  }
} 