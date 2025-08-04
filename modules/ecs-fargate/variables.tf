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

variable "enable_autoscaling" {
  description = "Enable autoscaling for the service"
  type        = bool
  default     = true
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization for autoscaling"
  type        = number
  default     = 70
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