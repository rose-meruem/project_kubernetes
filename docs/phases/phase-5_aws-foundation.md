# Phase 5 — AWS Foundation

## Status

Phase 5 is in progress.

Current state:

```text
GitHub Actions CI:     Complete
ECR registry:          Pending
EKS cluster:           Pending
Argo CD on EKS:        Pending
AWS ALB ingress:       Pending
TLS:                   Pending
```

---

## Goal

Move from a local kind cluster to AWS infrastructure.

Before Phase 5:

```text
Image built locally
Deployed manually with helm or via Argo CD on kind
No automated build or publish pipeline
```

After Phase 5:

```text
GitHub Actions builds and tests on every push
Merged image pushed to ECR with a commit SHA tag
Argo CD on EKS reads the updated values-prod.yaml
Application runs on EKS with ALB ingress and TLS
```

---

## Overall architecture

```text
push to main
→ GitHub Actions: test → build → push to ECR
→ GitHub Actions: update values-prod.yaml (image tag)
→ Argo CD on EKS: detects values-prod.yaml change
→ Argo CD: pulls new image from ECR
→ Argo CD: rolls out updated deployment on EKS
→ AWS ALB: serves traffic to url-shortener pods
```

---

## Phase 5 — Part 1: GitHub Actions CI

### Workflow location

```text
.github/workflows/ci.yml
```

### Triggers

```text
push to main     → test + build + push to ECR + update values-prod.yaml
pull_request     → test only
```

### Jobs

#### test

Runs on every push and pull request.

Uses a PostgreSQL service container to satisfy the `/ready` endpoint and link creation tests.

Service container configuration:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    env:
      POSTGRES_DB: urlshortener
      POSTGRES_USER: urlshortener
      POSTGRES_PASSWORD: urlshortener
    ports:
      - 5432:5432
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

The `DATABASE_URL` is set to `localhost:5432` because GitHub Actions service containers are reachable on `localhost` when jobs run on the host (not inside a container).

Test command:

```bash
python -m pytest -q
```

#### build-push

Runs only on `push` to `main`, after `test` passes.

Steps:

```text
1. Authenticate to AWS via OIDC (no long-lived credentials stored in secrets)
2. Login to Amazon ECR
3. Build Docker image from ./app
4. Push with tag sha-<short-sha> and latest
5. Update charts/url-shortener/values-prod.yaml with the new image URI and tag
6. Commit and push the values change back to main
```

Image tagging convention:

```text
<account-id>.dkr.ecr.<region>.amazonaws.com/url-shortener:sha-a1b2c3d
<account-id>.dkr.ecr.<region>.amazonaws.com/url-shortener:latest
```

The `sha-<short-sha>` tag is deterministic and traceable to the exact commit. Argo CD reads the updated `values-prod.yaml` and pulls the new image.

### Required GitHub secrets

```text
AWS_ROLE_ARN    IAM role ARN with ECR push and EKS describe permissions
AWS_REGION      AWS region where ECR and EKS are provisioned
```

These use OIDC federation. No `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` are stored in GitHub.

### OIDC trust policy (AWS side)

The IAM role needs a trust policy allowing GitHub Actions to assume it:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:rose-meruem/project_kubernetes:*"
    }
  }
}
```

The role needs these permissions:

```text
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:InitiateLayerUpload
ecr:UploadLayerPart
ecr:CompleteLayerUpload
ecr:PutImage
```

---

## Phase 5 — Part 2: ECR registry

Pending.

Steps to complete:

```text
1. Create ECR repository: url-shortener
2. Attach lifecycle policy to expire old untagged images
3. Note the registry URI for values-prod.yaml and the OIDC role
```

---

## Phase 5 — Part 3: EKS cluster

Pending.

Planned approach:

```text
eksctl create cluster \
  --name sovereign-idp \
  --region <region> \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

After the cluster is up:

```text
1. Install AWS Load Balancer Controller (for ALB ingress)
2. Install cert-manager (for TLS)
3. Install Argo CD
```

---

## Phase 5 — Part 4: Argo CD on EKS

Pending.

The existing `k8s/argocd/app-url-shortener.yaml` will be updated to:

```text
- repoURL: same GitHub repository
- valueFiles: values-prod.yaml  (instead of values-local.yaml)
- destination: EKS cluster API server
```

---

## Phase 5 — Part 5: AWS ALB ingress

Pending.

The `values-prod.yaml` already sets:

```yaml
ingress:
  className: traefik
  host: short.younessb.dev
  tls:
    enabled: true
    secretName: short-younessb-dev-tls
```

The `className` will be updated from `traefik` to `alb` once the AWS Load Balancer Controller is installed on EKS.

---

## Phase 5 outcome (target)

At the end of Phase 5, the project will claim:

```text
Implemented a complete GitOps delivery pipeline from GitHub to AWS EKS:
GitHub Actions CI/CD with OIDC authentication, ECR image registry,
EKS cluster, Argo CD automated sync, AWS ALB ingress, and TLS.
```
