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
  cluster_name = "${local.account_name}-prod-ecs"
  region       = "us-east-1"
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
