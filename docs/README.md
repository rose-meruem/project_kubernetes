# Kubernetes IDP Lab — Documentation

This directory contains the technical documentation for the Kubernetes IDP Lab project.

The project is being built incrementally as a DevOps/SRE portfolio project. Its purpose is to demonstrate practical Kubernetes platform engineering skills: application containerization, local Kubernetes deployment, Helm packaging, GitOps delivery with Argo CD, validation workflows, incident documentation, and later AWS-based infrastructure.

---

## Project scope

The project currently deploys a FastAPI URL shortener backed by PostgreSQL.

The application exposes:

```text
/health
/ready
/links
/links/{code}
/links/{code}/stats
```

The infrastructure currently includes:

```text
FastAPI application
PostgreSQL
Docker image build
kind local Kubernetes cluster
Helm chart
Argo CD GitOps deployment
Automated smoke tests
GitOps self-healing validation
```

Future cloud deployment must use AWS.

The intended AWS direction is:

```text
GitHub Actions
→ ECR image registry
→ EKS Kubernetes cluster
→ Argo CD GitOps reconciliation
→ AWS ingress/load balancing
→ observability and policy controls
```

---

## Documentation structure

```text
docs/
├── README.md
├── phases/
│   ├── phase-1_app-foundation.md
│   ├── phase-2_local-kubernetes.md
│   ├── phase-3_helm-local-deployment.md
│   ├── phase-4_argocd-gitops.md
│   └── phase-5_aws-foundation.md
├── incidents/
│   └── inc001_nftables-docker.md
└── evidence/
```

---

## Phase documentation

### Phase 1 — Application foundation

File:

```text
docs/phases/phase-1_app-foundation.md
```

Purpose:

```text
Build the core FastAPI URL shortener application with PostgreSQL integration, Docker support, health checks, readiness checks, and basic API behavior.
```

Main outcome:

```text
The app can run locally, connect to PostgreSQL, expose operational endpoints, create short links, and return link statistics.
```

---

### Phase 2 — Local Kubernetes foundation

File:

```text
docs/phases/phase-2_local-kubernetes.md
```

Purpose:

```text
Move the application from Docker-only execution to a local Kubernetes environment using kind.
```

Main outcome:

```text
The application and PostgreSQL can run inside Kubernetes with namespaces, workloads, services, probes, secrets, and local image loading.
```

---

### Phase 3 — Helm local deployment

File:

```text
docs/phases/phase-3_helm-local-deployment.md
```

Purpose:

```text
Package the Kubernetes resources as a Helm chart and deploy the application through repeatable Helm commands.
```

Main outcome:

```text
The URL shortener and PostgreSQL are deployed through Helm, with environment-specific values files and successful smoke-test validation.
```

---

### Phase 4 — Argo CD GitOps

File:

```text
docs/phases/phase-4_argocd-gitops.md
```

Purpose:

```text
Move from manual Helm deployment to GitOps delivery with Argo CD.
```

Main outcome:

```text
Argo CD deploys the Helm chart from GitHub, keeps the cluster synchronized with Git, and self-heals manual cluster drift.
```

Validated behavior:

```text
Manual scale to 0 replicas
→ Argo CD detects OutOfSync
→ Argo CD restores desired state
→ deployment returns to 1/1
→ smoke test passes
```

---

### Phase 5 — AWS foundation

File:

```text
docs/phases/phase-5_aws-foundation.md
```

Purpose:

```text
Move from local kind to AWS: GitHub Actions CI/CD, ECR image registry,
EKS cluster, Argo CD on EKS, AWS ALB ingress, and TLS.
```

Main outcome (in progress):

```text
Automated pipeline from git push to production on EKS,
with Argo CD GitOps reconciliation and AWS load-balanced ingress.
```

---

## Incident documentation

Incident files are stored in:

```text
docs/incidents/
```

They document operational problems encountered during the project.

Current incident:

```text
inc001_nftables-docker.md
```

Purpose:

```text
Document the Docker/networking issue related to nftables and local development, including symptoms, diagnosis, resolution, and lessons learned.
```

Incident documentation is important because it shows SRE-style reasoning:

```text
Symptom
Impact
Root cause
Fix
Prevention
Lessons learned
```

---

## Validation commands

Common validation commands:

```bash
make test
make build
make import-image
make validate-chart
make deploy-local
make smoke-test
make gitops-test
```

Cluster status:

```bash
make status
kubectl get pods -A
kubectl get applications -n argocd
```

Argo CD status:

```bash
make argocd-status
make argocd-check
```

---

## Current validated project state

The project has reached Phase 5 (AWS foundation, in progress).

Validated (local):

```text
FastAPI app:              Running
PostgreSQL:               Running
Helm chart:               Valid
Local deployment:         Working
Argo CD sync:             Synced
Smoke test:               Passed
Self-healing test:        Passed
```

Phase 5 status:

```text
GitHub Actions CI:        Complete (test + build-push to ECR)
ECR registry:             Pending
EKS cluster:              Pending
Argo CD on EKS:           Pending
AWS ALB ingress:          Pending
TLS:                      Pending
```

Known local limitation:

```text
Argo CD health may remain Progressing because the local Ingress has no assigned address.
```

This is acceptable for the current local phase because:

```text
Deployment is available
StatefulSet is ready
/health returns OK
/ready returns OK with DB reachable
Smoke test passes
Argo CD self-healing works
```

This should be revisited during the AWS phase, where ingress will be backed by AWS load balancing.
