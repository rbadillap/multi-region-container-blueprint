# Capacity provider strategies
locals {
  capacity_provider_strategies = {
    availability = [
      {
        capacity_provider = "FARGATE"
        weight           = 1
      }
    ]
    cost-optimized = [
      {
        capacity_provider = "FARGATE_SPOT"
        weight           = 1
      }
    ]
    balanced = [
      {
        capacity_provider = "FARGATE_SPOT"
        weight           = 1
      },
      {
        capacity_provider = "FARGATE"
        weight           = 0
      }
    ]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  dynamic "default_capacity_provider_strategy" {
    for_each = local.capacity_provider_strategies[var.strategy_profile]
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight           = default_capacity_provider_strategy.value.weight
    }
  }
}

# Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}


