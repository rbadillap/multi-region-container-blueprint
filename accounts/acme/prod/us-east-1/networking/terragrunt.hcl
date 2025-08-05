include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  account      = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account.locals.account_name

  # Environment-specific variables
  name_prefix = "${local.account_name}-prod"
  region      = "us-east-1"
  
  # VPC and subnet CIDR blocks
  vpc_cidr = "10.0.0.0/16"
  
  # Availability zones for us-east-1
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  # Public subnet CIDRs
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  
  # Private subnet CIDRs
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
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
