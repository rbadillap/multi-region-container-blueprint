variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
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