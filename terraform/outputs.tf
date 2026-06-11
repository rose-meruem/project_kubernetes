output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL for the url-shortener image"
  value       = aws_ecr_repository.url_shortener.repository_url
}

output "github_actions_role_arn" {
  description = "IAM role ARN to set as AWS_ROLE_ARN in GitHub secrets"
  value       = aws_iam_role.github_actions.arn
}

output "configure_kubectl" {
  description = "Run this command after apply to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
