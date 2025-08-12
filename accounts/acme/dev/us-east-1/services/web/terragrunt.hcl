include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../../modules/ecs/service"
}

dependency "networking" {
  config_path = "../../infrastructure/vpc"
}

dependency "ecs_cluster" {
  config_path = "../../infrastructure/ecs"
}

inputs = {
  # Service configuration
  service_name = "web"
  cluster_name = dependency.ecs_cluster.outputs.ecs_cluster_name
  cluster_id   = dependency.ecs_cluster.outputs.ecs_cluster_arn
  
  # infra references
  vpc_id                  = dependency.networking.outputs.vpc_id
  public_subnet_ids       = dependency.networking.outputs.public_subnet_ids
  private_subnet_ids      = dependency.networking.outputs.private_subnet_ids
  task_execution_role_arn = dependency.ecs_cluster.outputs.task_execution_role_arn
  task_role_arn           = dependency.ecs_cluster.outputs.task_role_arn
  
  # Container configuration
  container_name        = "web"
  container_image       = "nginx:alpine"
  container_port        = 80
  container_environment = [
    {
      name  = "NGINX_HOST"
      value = "web.acme.dev"
    }
  ]
  
  # Task configuration
  task_cpu              = 256
  task_memory           = 512
  service_desired_count = 2
  service_min_count     = 1
  service_max_count     = 4
  
  # Auto-scaling and observability
  scaling_profile       = "balanced"  # Balanced scaling: CPU-based with moderate thresholds
  observability_profile = "standard"  # Standard monitoring: CloudWatch logs + basic metrics
  
  # Health check
  health_check_path = "/"
  
  # Tags
  tags = {
    Component   = "application"
    Environment = "dev"
    Application = "web"
    ManagedBy   = "terragrunt"
  }
}
