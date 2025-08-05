#!/bin/bash

# MRCB Generate Terragrunt Configs Script
# This script generates terragrunt.hcl files for all regions and environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to generate networking terragrunt.hcl
generate_networking_config() {
    local account=$1
    local env=$2
    local region=$3
    
    local config_dir="accounts/${account}/${env}/${region}/networking"
    local config_file="${config_dir}/terragrunt.hcl"
    
    if [ ! -f "$config_file" ]; then
        print_status "Generating networking config for ${account}/${env}/${region}"
        mkdir -p "$config_dir"
        
        # Determine CIDR blocks based on region
        local vpc_cidr=""
        local public_subnet_cidrs=""
        local private_subnet_cidrs=""
        local availability_zones=""
        
        case $region in
            "us-east-1")
                vpc_cidr="10.0.0.0/16"
                public_subnet_cidrs='["10.0.1.0/24", "10.0.2.0/24"]'
                private_subnet_cidrs='["10.0.10.0/24", "10.0.11.0/24"]'
                availability_zones='["us-east-1a", "us-east-1b"]'
                ;;
            "eu-west-1")
                vpc_cidr="10.1.0.0/16"
                public_subnet_cidrs='["10.1.1.0/24", "10.1.2.0/24"]'
                private_subnet_cidrs='["10.1.10.0/24", "10.1.11.0/24"]'
                availability_zones='["eu-west-1a", "eu-west-1b"]'
                ;;
            *)
                print_error "Unsupported region: $region"
                return 1
                ;;
        esac
        
        cat > "$config_file" << EOF
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  account      = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account.locals.account_name

  # Environment-specific variables
  name_prefix = "\${local.account_name}-${env}"
  region      = "${region}"
  
  # VPC and subnet CIDR blocks
  vpc_cidr = "${vpc_cidr}"
  
  # Availability zones for ${region}
  availability_zones = ${availability_zones}
  
  # Public subnet CIDRs
  public_subnet_cidrs = ${public_subnet_cidrs}
  
  # Private subnet CIDRs
  private_subnet_cidrs = ${private_subnet_cidrs}
}

terraform {
  source = "../../../../../modules/networking"
}

inputs = {
  name_prefix           = local.name_prefix
  vpc_cidr              = local.vpc_cidr
  availability_zones    = local.availability_zones
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
  enable_nat_gateway    = true
  tags = {
    Component = "networking"
    Region    = local.region
  }
}
EOF
        print_status "Created ${config_file}"
    else
        print_warning "Config file already exists: ${config_file}"
    fi
}

# Function to generate ECS terragrunt.hcl
generate_ecs_config() {
    local account=$1
    local env=$2
    local region=$3
    
    local config_dir="accounts/${account}/${env}/${region}/ecs"
    local config_file="${config_dir}/terragrunt.hcl"
    
    if [ ! -f "$config_file" ]; then
        print_status "Generating ECS config for ${account}/${env}/${region}"
        mkdir -p "$config_dir"
        
        cat > "$config_file" << EOF
include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

locals {
  account      = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account.locals.account_name

  # Environment-specific variables
  cluster_name = "\${local.account_name}-${env}-ecs"
  region       = "${region}"
}

terraform {
  source = "../../../../../modules/ecs-fargate"
}

inputs = {
  cluster_name        = local.cluster_name
  vpc_id              = dependency.networking.outputs.vpc_id
  public_subnet_ids   = dependency.networking.outputs.public_subnet_ids
  private_subnet_ids  = dependency.networking.outputs.private_subnet_ids
  
  # Container configuration
  container_name  = "app"
  container_image = "nginx:alpine"
  container_port  = 80
  
  # Task configuration
  task_cpu    = 256
  task_memory = 512
  
  # Service configuration
  service_desired_count = 2
  service_min_count     = 1
  service_max_count     = 4
  
  # Autoscaling
  enable_autoscaling      = true
  autoscaling_cpu_target  = 70
  
  # Health check
  health_check_path = "/"
  
  tags = {
    Component = "ecs"
    Region    = local.region
  }
}
EOF
        print_status "Created ${config_file}"
    else
        print_warning "Config file already exists: ${config_file}"
    fi
}

# Function to generate EKS terragrunt.hcl
generate_eks_config() {
    local account=$1
    local env=$2
    local region=$3
    
    local config_dir="accounts/${account}/${env}/${region}/eks"
    local config_file="${config_dir}/terragrunt.hcl"
    
    if [ ! -f "$config_file" ]; then
        print_status "Generating EKS config for ${account}/${env}/${region}"
        mkdir -p "$config_dir"
        
        cat > "$config_file" << EOF
include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

locals {
  account      = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account.locals.account_name

  # Environment-specific variables
  cluster_name = "\${local.account_name}-${env}-eks"
  region       = "${region}"
}

terraform {
  source = "../../../../../modules/eks"
}

inputs = {
  cluster_name        = local.cluster_name
  kubernetes_version  = "1.29"
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
  
  # IAM Role configuration for EKS access
  create_admin_role   = true
  admin_role_arns     = []  # Will use root account as fallback
  create_viewer_role  = true
  viewer_role_arns    = []
  map_users           = []
  
  tags = {
    Component = "eks"
    Region    = local.region
  }
}
EOF
        print_status "Created ${config_file}"
    else
        print_warning "Config file already exists: ${config_file}"
    fi
}

# Main function
main() {
    local account=${1:-"acme"}
    local env=${2:-"dev"}
    local region=${3:-"us-east-1"}
    
    print_status "Starting terragrunt config generation..."
    print_status "Account: ${account}"
    print_status "Environment: ${env}"
    print_status "Region: ${region}"
    echo
    
    # Check if account.hcl exists
    if [ ! -f "accounts/${account}/account.hcl" ]; then
        print_error "Account configuration file not found: accounts/${account}/account.hcl"
        exit 1
    fi
    
    # Generate configs for all components
    generate_networking_config "$account" "$env" "$region"
    generate_ecs_config "$account" "$env" "$region"
    generate_eks_config "$account" "$env" "$region"
    
    echo
    print_status "Config generation completed!"
    print_status "You can now run Terragrunt commands to deploy your infrastructure."
    echo
    print_status "Example commands:"
    echo "  cd accounts/${account}/${env}/${region}/networking"
    echo "  terragrunt init"
    echo "  terragrunt plan"
    echo "  terragrunt apply"
}

# Show usage
usage() {
    echo "Usage: $0 [account] [environment] [region]"
    echo "  account:     Account name (default: acme)"
    echo "  environment: Environment name (default: dev)"
    echo "  region:      AWS region (default: us-east-1)"
    echo
    echo "Example: $0 acme prod eu-west-1"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@" 