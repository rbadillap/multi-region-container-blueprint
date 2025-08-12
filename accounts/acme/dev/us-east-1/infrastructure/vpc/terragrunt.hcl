include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  account      = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account.locals.account_name

  # Environment-specific variables for resource naming and identification
  name_prefix = "${local.account_name}-dev"  # Creates resources like: acme-dev-vpc, acme-dev-public-us-east-1a
  region      = "us-east-1"
  
  # VPC CIDR block - /16 provides 65,536 IP addresses (10.0.0.0 - 10.0.255.255)
  vpc_cidr = "10.0.0.0/16"
  
  # Multi-AZ setup for high availability - using 2 AZs for redundancy
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  # Public subnet CIDRs - /24 provides 256 IP addresses per subnet
  # These subnets will have direct internet access via Internet Gateway
  # Used for: Load Balancers, Bastion hosts, NAT Gateways
  public_subnet_cidrs = [
    "10.0.1.0/24",  # us-east-1a - 256 IPs (10.0.1.0 - 10.0.1.255)
    "10.0.2.0/24"   # us-east-1b - 256 IPs (10.0.2.0 - 10.0.2.255)
  ]
  
  # Private subnet CIDRs - /24 provides 256 IP addresses per subnet
  # These subnets have no direct internet access, only via NAT Gateway
  # Used for: Application servers, Databases, Internal services
  private_subnet_cidrs = [
    "10.0.10.0/24", # us-east-1a - 256 IPs (10.0.10.0 - 10.0.10.255)
    "10.0.11.0/24"  # us-east-1b - 256 IPs (10.0.11.0 - 10.0.11.255)
  ]
}

terraform {
  source = "../../../../../../modules/vpc"
}

inputs = {
  name_prefix           = local.name_prefix
  vpc_cidr              = local.vpc_cidr
  availability_zones    = local.availability_zones
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
  
  # NAT Gateway enables private subnets to access internet (required for package updates, external APIs)
  # Cost: ~$45/month per NAT Gateway + data processing fees
  enable_nat_gateway    = false
  
  tags = {
    Component   = "networking"
    Region      = local.region
    Environment = "dev"
    ManagedBy   = "terragrunt"
  }
} 