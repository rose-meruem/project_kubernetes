# Phase 6 — Terraform IaC

## Status

Planned. Not started.

---

## Goal

Phase 5 built the AWS infrastructure through manual `eksctl` and `aws` CLI commands. Those commands are not reproducible — if the cluster is deleted, every step has to be remembered and re-run by hand.

Phase 6 replaces all of that with Terraform so the entire AWS platform is defined as code, version-controlled in Git, and reproducible with a single command.

Before Phase 6:

```text
Infrastructure created by running commands manually
No record of what was created or why
Cannot reproduce the environment reliably
```

After Phase 6:

```text
terraform apply
→ VPC and subnets
→ EKS cluster and managed nodegroup
→ ECR repository with lifecycle policy
→ EBS CSI driver addon
→ IAM roles: GitHub OIDC, ALB controller, EBS CSI
→ All policies attached
```

---

## Planned module structure

```text
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── modules/
    ├── eks/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ecr/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── iam/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## What Terraform will manage

### Networking

```text
VPC with public and private subnets across 3 AZs
Internet gateway
NAT gateway (for private node egress)
Route tables
```

### EKS

```text
EKS cluster (Kubernetes 1.34)
Managed nodegroup: t3.medium, min 1, max 3
Cluster OIDC provider
EBS CSI driver addon
AWS Load Balancer Controller addon (via Helm provider)
```

### ECR

```text
Repository: url-shortener
Image scanning on push
Lifecycle policy: keep 10 tagged, expire untagged after 1 day
```

### IAM

```text
GitHub Actions OIDC role (ECR push + EKS describe)
AWS Load Balancer Controller role
EBS CSI driver role
All managed policies attached
```

---

## Why this matters

In practice, most DevOps/SRE roles expect infrastructure to be managed through code, not CLI commands. Terraform is the most widely used IaC tool in the industry.

Replacing Phase 5's manual commands with Terraform demonstrates:

```text
Infrastructure as Code discipline
Reproducible environments
Version-controlled infrastructure changes
Separation of platform concerns from application concerns
```

---

## Phase 6 outcome (target)

```text
Implemented a fully reproducible AWS platform with Terraform:
VPC, EKS, ECR, IAM roles, and Kubernetes addons provisioned from code,
replacing all manual Phase 5 CLI commands.
```
