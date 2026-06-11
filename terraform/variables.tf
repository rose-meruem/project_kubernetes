variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "sovereign-idp"
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format"
  type        = string
  default     = "rose-meruem/project_kubernetes"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}
