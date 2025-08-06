variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "nginx:alpine"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "container_environment" {
  description = "Environment variables for the container"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "task_cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MiB"
  type        = number
  default     = 512
}

variable "service_desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "service_min_count" {
  description = "Minimum number of tasks for autoscaling"
  type        = number
  default     = 1
}

variable "service_max_count" {
  description = "Maximum number of tasks for autoscaling"
  type        = number
  default     = 10
}

variable "enable_cpu_autoscaling" {
  description = "Enable CPU-based autoscaling"
  type        = bool
  default     = true
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization for autoscaling"
  type        = number
  default     = 70
}

variable "enable_memory_autoscaling" {
  description = "Enable memory-based autoscaling"
  type        = bool
  default     = false
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization for autoscaling"
  type        = number
  default     = 80
}

variable "enable_cloudwatch_dashboard" {
  description = "Enable CloudWatch dashboard for monitoring"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for monitoring"
  type        = bool
  default     = false
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarms"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory utilization threshold for alarms"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "List of ARNs for alarm actions (SNS topics, etc.)"
  type        = list(string)
  default     = []
}

variable "health_check_path" {
  description = "Health check path for the ALB"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "observability_profile" {
  description = <<-EOT
    Observability configuration profile:
    - mission-critical: CPU only + alerts (high signal, zero noise) for critical production
    - standard: CPU + Memory with alerts and basic dashboard for staging/QA
    - external: Exposes ports/env vars for external APM tools (Datadog, Honeycomb, etc.)
  EOT
  type        = string
  default     = "standard"
  
  validation {
    condition     = contains(["mission-critical", "standard", "external"], var.observability_profile)
    error_message = "Observability profile must be one of: mission-critical, standard, external"
  }
}

variable "scaling_profile" {
  description = <<-EOT
    Auto-scaling configuration profile:
    - conservative: Scales only if CPU > 80% for 5 min, minimal noise (stable production)
    - balanced: Scales by CPU > 70% or Memory > 75%, defined cooldowns (typical services)
    - responsive: Aggressively scales by CPU, Memory or ALB RequestCountPerTarget (dynamic apps)
  EOT
  type        = string
  default     = "balanced"
  
  validation {
    condition     = contains(["conservative", "balanced", "responsive"], var.scaling_profile)
    error_message = "Scaling profile must be one of: conservative, balanced, responsive"
  }
}

variable "strategy_profile" {
  description = <<-EOT
    Capacity provider strategy profile:
    - availability: Uses FARGATE for maximum availability (production)
    - cost-optimized: Uses FARGATE_SPOT for cost savings (development)
    - balanced: Uses FARGATE_SPOT with FARGATE fallback (staging)
  EOT
  type        = string
  default     = "balanced"
  
  validation {
    condition     = contains(["availability", "cost-optimized", "balanced"], var.strategy_profile)
    error_message = "Strategy profile must be one of: availability, cost-optimized, balanced"
  }
} 