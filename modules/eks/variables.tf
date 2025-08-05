variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "create_admin_role" {
  description = "Whether to create an admin IAM role for EKS access"
  type        = bool
  default     = true
}

variable "admin_role_arns" {
  description = "List of IAM role ARNs that can assume the admin role"
  type        = list(string)
  default     = []
}

variable "create_viewer_role" {
  description = "Whether to create a viewer IAM role for EKS access"
  type        = bool
  default     = false
}

variable "viewer_role_arns" {
  description = "List of IAM role ARNs that can assume the viewer role"
  type        = list(string)
  default     = []
}

variable "map_users" {
  description = "List of IAM users to map to Kubernetes RBAC"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
} 