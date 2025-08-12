# ECS Service Module

This module creates an ECS Fargate service with Application Load Balancer, auto-scaling, and observability features.

## Features

- **ECS Fargate Service**: Deploys containerized applications using AWS Fargate
- **Application Load Balancer**: Provides HTTP/HTTPS load balancing
- **Auto Scaling**: CPU and memory-based auto-scaling with configurable profiles
- **Security Groups**: Separate security groups for ALB and ECS tasks
- **CloudWatch Integration**: Logging, monitoring, and alerting
- **Task Definition**: Configurable container definitions with environment variables

## Usage

```hcl
module "ecs_service" {
  source = "../../modules/ecs/service"

  # Required variables
  service_name         = "my-app"
  cluster_name         = "my-cluster"
  cluster_id           = module.ecs_cluster.ecs_cluster_arn
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn        = module.ecs_cluster.task_role_arn

  # Container configuration
  container_name       = "app"
  container_image      = "nginx:alpine"
  container_port       = 80
  container_environment = [
    {
      name  = "NODE_ENV"
      value = "production"
    }
  ]

  # Task configuration
  task_cpu             = 256
  task_memory          = 512
  service_desired_count = 2
  service_min_count    = 1
  service_max_count    = 10

  # Auto-scaling profile
  scaling_profile      = "balanced" # conservative, balanced, responsive

  # Observability profile
  observability_profile = "standard" # mission-critical, standard

  # Health check
  health_check_path    = "/health"

  # Tags
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

**Profiles**: This module uses predefined profiles for auto-scaling and observability to simplify configuration. Choose the profiles that best fit your application needs:

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| service_name | Name of the ECS service | `string` | n/a | yes |
| cluster_name | Name of the ECS cluster | `string` | n/a | yes |
| cluster_id | ID of the ECS cluster | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| public_subnet_ids | List of public subnet IDs for ALB | `list(string)` | n/a | yes |
| private_subnet_ids | List of private subnet IDs for ECS tasks | `list(string)` | n/a | yes |
| task_execution_role_arn | ARN of the task execution role | `string` | n/a | yes |
| task_role_arn | ARN of the task role | `string` | n/a | yes |
| container_name | Name of the container | `string` | `"app"` | no |
| container_image | Docker image for the container | `string` | `"nginx:alpine"` | no |
| container_port | Port the container listens on | `number` | `80` | no |
| container_environment | Environment variables for the container | `list(object({name = string, value = string}))` | `[]` | no |
| task_cpu | CPU units for the task (1024 = 1 vCPU) | `number` | `256` | no |
| task_memory | Memory for the task in MiB | `number` | `512` | no |
| service_desired_count | Desired number of tasks | `number` | `2` | no |
| service_min_count | Minimum number of tasks for autoscaling | `number` | `1` | no |
| service_max_count | Maximum number of tasks for autoscaling | `number` | `10` | no |
| alarm_actions | List of ARNs for alarm actions (SNS topics, etc.) | `list(string)` | `[]` | no |
| health_check_path | Health check path for the ALB | `string` | `"/"` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |
| observability_profile | Observability configuration profile | `string` | `"standard"` | no |
| scaling_profile | Auto-scaling configuration profile | `string` | `"balanced"` | no |

## Outputs

| Name | Description |
|------|-------------|
| ecs_service_name | Name of the ECS service |
| ecs_service_arn | ARN of the ECS service |
| alb_dns_name | DNS name of the Application Load Balancer |
| alb_arn | ARN of the Application Load Balancer |
| target_group_arn | ARN of the target group |
| task_definition_arn | ARN of the task definition |
| alb_security_group_id | ID of the ALB security group |
| ecs_tasks_security_group_id | ID of the ECS tasks security group |
| cloudwatch_log_group_name | Name of the CloudWatch log group |
| cloudwatch_dashboard_name | Name of the CloudWatch dashboard |

## Auto-scaling Profiles

### Conservative
- Scales only if CPU > 80% for 5 minutes
- Minimal noise, suitable for stable production workloads

### Balanced (Default)
- Scales by CPU > 70% or Memory > 75%
- Defined cooldowns, suitable for typical services

### Responsive
- Aggressively scales by CPU, Memory, or ALB RequestCountPerTarget
- Suitable for dynamic applications

## Observability Profiles

### Standard (Default)
- CPU + Memory monitoring with alerts
- Basic CloudWatch dashboard
- 30-day log retention

### Mission-critical
- CPU-only monitoring with alerts
- No dashboard (high signal, zero noise)
- 90-day log retention

## Dependencies

This module depends on the `ecs/cluster` module for:
- ECS Cluster
- Task Execution Role
- Task Role

## Security

- ALB security group allows HTTP (80) and HTTPS (443) from anywhere
- ECS tasks security group allows traffic only from ALB
- Both security groups allow all outbound traffic
- Tasks run in private subnets without public IP assignment
