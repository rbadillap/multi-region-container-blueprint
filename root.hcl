# Root root.hcl - Common configuration for all environments
locals {
  # Parse the path to extract environment information
  path_parts = split("/", path_relative_to_include())
  
  # Extract client, environment, region, and component from path
  client     = local.path_parts[1]
  env        = local.path_parts[2]
  region     = local.path_parts[3]
  component  = local.path_parts[4]
  
  # Common tags
  common_tags = {
    Project     = "MRCB"
    ManagedBy   = "Terragrunt"
    Environment = local.env
    Client      = local.client
    Region      = local.region
  }
}

# Configure Terragrunt to automatically store tfstate files in S3
remote_state {
  backend = "s3"
  config = {
    bucket         = "mrcb-terraform-state-${local.client}-${local.env}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "mrcb-terraform-locks-${local.client}-${local.env}"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure Terraform
terraform {
  # Force Terraform to keep trying to acquire a lock for up to 20 minutes
  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()
    arguments = [
      "-lock-timeout=20m"
    ]
  }
}

# Provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  
  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}
EOF
} 