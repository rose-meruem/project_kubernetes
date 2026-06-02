# Phase 2 — Local Kubernetes Foundation

## Status

Phase 2 is functionally complete.

The project moved from running the application with Docker/PostgreSQL locally to running it inside a local Kubernetes cluster.

The local cluster currently uses:

```text
kind
```

The cluster name is:

```text
sovereign-idp
```

The application namespace is:

```text
url-shortener
```

---

## Goal

The goal of Phase 2 was to create a local Kubernetes foundation before introducing Helm, GitOps, preview environments, observability, or cloud infrastructure.

This phase answers the question:

```text
Can the application run correctly as Kubernetes workloads?
```

Before this phase:

```text
FastAPI app + PostgreSQL run locally through Docker / local development commands.
```

After this phase:

```text
FastAPI app + PostgreSQL run inside Kubernetes with workloads, services, probes, secrets, and namespace isolation.
```

---

## Components introduced

Phase 2 introduced the Kubernetes runtime layer for the application.

Main components:

```text
kind cluster
url-shortener namespace
FastAPI Kubernetes workload
PostgreSQL Kubernetes workload
Kubernetes Service for the API
Kubernetes Service for PostgreSQL
Kubernetes Secret for database configuration
Health and readiness probes
Local Docker image loading into kind
Smoke-test validation
```

---

## Local cluster

The local cluster is created with:

```bash
kind create cluster --name sovereign-idp
```

The Makefile target is:

```bash
make dev-up
```

Relevant Makefile variables:

```makefile
KIND_CLUSTER=sovereign-idp
NAMESPACE=url-shortener
IMAGE_NAME=url-shortener
IMAGE_TAG=local
```

Cluster validation:

```bash
kubectl get nodes
```

Expected result:

```text
sovereign-idp-control-plane   Ready
```

---

## Image workflow

Because this phase uses a local kind cluster, the application image must be built locally and loaded into kind.

Build image:

```bash
make build
```

Load image into kind:

```bash
make import-image
```

Equivalent command:

```bash
kind load docker-image url-shortener:local --name sovereign-idp
```

This makes the image available to the Kubernetes nodes without using an external registry.

---

## Namespace

The application runs in a dedicated namespace:

```text
url-shortener
```

Namespace creation:

```bash
kubectl create namespace url-shortener --dry-run=client -o yaml | kubectl apply -f -
```

This isolates the app resources from system namespaces and prepares the project for later environment separation, such as:

```text
preview environments
production namespace
monitoring namespace
argocd namespace
```

---

## Workloads

The application consists of two main runtime components:

```text
FastAPI API
PostgreSQL database
```

The API runs as a Kubernetes workload with:

```text
container image: url-shortener:local
container port: 8000
liveness probe: /health
readiness probe: /ready
startup probe: /health
```

The PostgreSQL component runs with:

```text
image: postgres:16-alpine
port: 5432
database: urlshortener
user: urlshortener
```

PostgreSQL readiness is checked with:

```text
pg_isready -U urlshortener
```

---

## Services

The application requires internal Kubernetes service discovery.

The API service exposes the FastAPI app inside the cluster:

```text
url-shortener
```

The PostgreSQL service exposes the database to the API:

```text
url-shortener-postgres
```

The application connects to PostgreSQL through the Kubernetes service DNS name rather than through localhost.

This is important because in Kubernetes:

```text
localhost inside the API pod = the API container itself
```

not the PostgreSQL pod.

---

## Readiness and health checks

The app exposes two operational endpoints:

```text
/health
/ready
```

`/health` checks whether the API process is alive.

`/ready` checks whether the application is ready to serve traffic, including whether the database is reachable.

Expected `/health` result:

```json
{"status":"ok"}
```

Expected `/ready` result:

```json
{"status":"ok","db":"reachable"}
```

This distinction matters for Kubernetes operations:

```text
liveness probe  -> should the container be restarted?
readiness probe -> should the pod receive traffic?
```

---

## Validation

Phase 2 is validated by checking Kubernetes resources and running the smoke test.

Check pods:

```bash
kubectl get pods -n url-shortener
```

Expected:

```text
url-shortener-...          1/1 Running
url-shortener-postgres-0   1/1 Running
```

Check deployment:

```bash
kubectl get deploy -n url-shortener
```

Expected:

```text
url-shortener   1/1
```

Run smoke test:

```bash
make smoke-test
```

Expected smoke-test sequence:

```text
[1/5] Checking /health
[2/5] Checking /ready
[3/5] Creating short link
[4/5] Fetching link stats
[5/5] Smoke test completed successfully
```

---

## Lessons learned

### Kubernetes resources can persist after refactors

During local development, old resources may remain in the namespace after manifests or chart templates are changed.

Example:

```text
An old PostgreSQL Deployment can coexist with a newer PostgreSQL StatefulSet if the old object is not deleted.
```

This can cause confusing behavior because Kubernetes will continue running resources that are no longer part of the intended design.

Useful cleanup command:

```bash
kubectl delete namespace url-shortener --ignore-not-found=true
```

Then redeploy.

---

### Readiness should include database reachability

An API can be alive while still being unable to serve real traffic because the database is unavailable.

That is why `/ready` checks the PostgreSQL connection.

This is more operationally useful than a simple process-only health check.

---

### Local Kubernetes needs local image loading

In kind, building a Docker image on the host does not automatically make it available inside the cluster.

This is why the workflow includes:

```bash
kind load docker-image url-shortener:local --name sovereign-idp
```

Without this step, Kubernetes may fail to pull the image.

---

## Phase 2 outcome

At the end of Phase 2, the project can claim:

```text
Deployed a FastAPI/PostgreSQL application into a local kind Kubernetes cluster with namespace isolation, Kubernetes services, health/readiness probes, local image loading, and smoke-test validation.
```

Phase 2 created the foundation needed for Phase 3 Helm packaging.
