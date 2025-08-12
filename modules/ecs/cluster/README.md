# ECS Fargate Cluster Module

This module creates an ECS Fargate cluster with capacity providers and IAM roles for task execution.

## Features

- **ECS Fargate Cluster**: Creates an ECS cluster optimized for Fargate workloads
- **Capacity Providers**: Configurable capacity provider strategies (FARGATE, FARGATE_SPOT)
- **IAM Roles**: Task execution and task roles for ECS services
- **Container Insights**: Enables CloudWatch Container Insights for monitoring

## Usage

```hcl
module "ecs_cluster" {
  source = "../../modules/ecs/cluster"

  # Required variables
  cluster_name = "my-cluster"

  # Capacity provider strategy
  strategy_profile = "balanced" # availability, cost-optimized, balanced

  # Tags
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the ECS cluster | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |
| strategy_profile | Capacity provider strategy profile | `string` | `"balanced"` | no |

## Outputs

| Name | Description |
|------|-------------|
| ecs_cluster_name | Name of the ECS cluster |
| ecs_cluster_arn | ARN of the ECS cluster |
| task_execution_role_arn | ARN of the task execution role |
| task_role_arn | ARN of the task role |

## Capacity Provider Strategies

### Availability
- Uses FARGATE for maximum availability
- Suitable for production workloads
- Higher cost but guaranteed capacity

### Cost-optimized
- Uses FARGATE_SPOT for cost savings
- Suitable for development and testing
- Lower cost but may be interrupted

### Balanced (Default)
- Uses FARGATE_SPOT with FARGATE fallback
- Suitable for staging environments
- Good balance of cost and availability

## Dependencies

This module has no external dependencies and can be used independently.

## Related Modules

- `ecs/service`: Use this module to create ECS services that run on the cluster created by this module
