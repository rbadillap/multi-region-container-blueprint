output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.main.arn
}

output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

# Kubeconfig for kubectl access
output "kubeconfig" {
  description = "Kubeconfig for kubectl access"
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [
      {
        name = aws_eks_cluster.main.name
        cluster = {
          server                     = aws_eks_cluster.main.endpoint
          certificate-authority-data = aws_eks_cluster.main.certificate_authority[0].data
        }
      }
    ]
    contexts = [
      {
        name = aws_eks_cluster.main.name
        context = {
          cluster = aws_eks_cluster.main.name
          user    = aws_eks_cluster.main.name
        }
      }
    ]
    users = [
      {
        name = aws_eks_cluster.main.name
        user = {
          exec = {
            apiVersion = "client.authentication.k8s.io/v1beta1"
            command    = "aws"
            args = [
              "eks",
              "get-token",
              "--cluster-name",
              aws_eks_cluster.main.name,
              "--region",
              data.aws_region.current.name
            ]
          }
        }
      }
    ]
  })
}

# Data source for current region
data "aws_region" "current" {} 