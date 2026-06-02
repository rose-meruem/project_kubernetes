# Phase 3 — Helm Local Deployment

## Status

Phase 3 is complete.

The Kubernetes resources for the URL shortener application were packaged into a Helm chart and validated through local deployment on the kind cluster.

The application and PostgreSQL are currently deployable through:

```bash
make deploy-local
```

and validated through:

```bash
make smoke-test
```

---

## Goal

The goal of Phase 3 was to move from direct Kubernetes manifests to a reusable Helm chart.

Before Phase 3:

```text
Kubernetes resources were managed directly.
```

After Phase 3:

```text
Application resources are packaged as a Helm chart with values files for different environments.
```

This makes the deployment more repeatable and prepares the project for:

```text
Argo CD GitOps
preview environments
production values
AWS deployment later
```

---

## Helm chart location

The chart is located at:

```text
charts/url-shortener
```

Main files:

```text
charts/url-shortener/Chart.yaml
charts/url-shortener/values.yaml
charts/url-shortener/values-local.yaml
charts/url-shortener/values-preview.yaml
charts/url-shortener/values-prod.yaml
charts/url-shortener/templates/
```

The local values file is:

```text
charts/url-shortener/values-local.yaml
```

The Makefile variable is:

```makefile
VALUES_LOCAL=./charts/url-shortener/values-local.yaml
```

---

## Templates

The chart includes templates for the application and database resources.

Main template responsibilities:

```text
FastAPI Deployment
FastAPI Service
PostgreSQL StatefulSet
PostgreSQL Service
PostgreSQL PVC
Secret
ConfigMap
ServiceAccount
Ingress
Helm helper labels/selectors
```

The old PostgreSQL deployment-style template was removed and replaced by a StatefulSet-based design.

This is more appropriate for PostgreSQL because the database needs stable identity and persistent storage.

---

## Values files

The chart uses values files to separate environment-specific settings.

Current values files:

```text
values.yaml
values-local.yaml
values-preview.yaml
values-prod.yaml
```

Purpose:

```text
values.yaml         default shared values
values-local.yaml   local kind development values
values-preview.yaml future pull-request preview environment values
values-prod.yaml    future production/AWS values
```

This structure prepares the project for later deployment flows:

```text
local development
preview environments
production deployment
```

---

## Local deployment workflow

The local deployment target is:

```bash
make deploy-local
```

The target performs:

```text
1. Load local Docker image into kind
2. Create the url-shortener namespace if needed
3. Run helm upgrade --install
4. Wait for API deployment rollout
```

Relevant Makefile target:

```makefile
deploy-local: import-image
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install $(APP_NAME) $(CHART) \
		--namespace $(NAMESPACE) \
		-f $(VALUES_LOCAL)
	kubectl rollout status deployment/$(APP_NAME) -n $(NAMESPACE) --timeout=120s
```

---

## Chart validation workflow

The Helm chart can be validated without deploying.

Lint chart:

```bash
make helm-lint
```

Render chart:

```bash
make helm-template
```

Validate both:

```bash
make validate-chart
```

Relevant Makefile targets:

```makefile
helm-lint:
	helm lint $(CHART)

helm-template:
	helm template $(APP_NAME) $(CHART) -f $(VALUES_LOCAL) >/tmp/url-shortener-rendered.yaml

validate-chart: helm-lint helm-template
```

The rendered output is written to:

```text
/tmp/url-shortener-rendered.yaml
```

This is useful for debugging template errors before deploying to Kubernetes.

---

## Runtime validation

After Helm deployment, the runtime was validated with Kubernetes status checks and the smoke test.

Expected pods:

```text
url-shortener-...          1/1 Running
url-shortener-postgres-0   1/1 Running
```

Expected deployment:

```text
url-shortener   1/1 available
```

Expected StatefulSet:

```text
url-shortener-postgres   1/1 ready
```

Smoke test:

```bash
make smoke-test
```

Expected result:

```text
[1/5] Checking /health
{"status":"ok"}

[2/5] Checking /ready
{"status":"ok","db":"reachable"}

[3/5] Creating short link
{"code":"...","original_url":"https://example.com/"}

[4/5] Fetching link stats
{"code":"...","accesses":0}

[5/5] Smoke test completed successfully
```

---

## Issues fixed during Phase 3

### Issue 1 — Missing PostgreSQL password key

Symptom:

```text
PostgreSQL container failed to start
CreateContainerConfigError
```

Cause:

```text
The Kubernetes Secret did not expose the expected POSTGRES_PASSWORD key.
```

Fix:

```text
Updated the Helm Secret template and values so PostgreSQL receives POSTGRES_PASSWORD correctly.
```

Lesson:

```text
Secret key names must match exactly what the container image expects.
```

---

### Issue 2 — PostgreSQL startup permission issue

Symptom:

```text
PostgreSQL entered CrashLoopBackOff
chmod/chown Operation not permitted
```

Cause:

```text
The security context was too restrictive for the official PostgreSQL image initialization behavior.
```

Fix:

```text
Adjusted the PostgreSQL security context and added PGDATA to use a safer data directory path.
```

Lesson:

```text
Security hardening must be tested against image initialization requirements.
```

---

### Issue 3 — Old PostgreSQL Deployment conflict

Symptom:

```text
Old PostgreSQL Deployment and new PostgreSQL StatefulSet coexisted.
```

Cause:

```text
Kubernetes does not automatically remove old resources just because templates are renamed or removed locally.
```

Fix:

```text
Cleaned the local namespace and redeployed the Helm chart.
```

Useful cleanup command:

```bash
kubectl delete namespace url-shortener --ignore-not-found=true
```

Lesson:

```text
During chart refactors, stale resources can survive and create misleading cluster state.
```

---

## Why StatefulSet for PostgreSQL

PostgreSQL is stateful.

A StatefulSet is more appropriate than a Deployment because it provides:

```text
stable pod identity
stable network identity
better fit for persistent storage
ordered lifecycle behavior
```

The database uses a PVC for persistent data.

Current PostgreSQL image:

```text
postgres:16-alpine
```

Current database settings:

```text
database: urlshortener
user: urlshortener
PGDATA: /var/lib/postgresql/data/pgdata
```

---

## Why Helm matters for this project

Helm adds a deployment abstraction that is useful for platform engineering.

It allows the same application chart to be deployed with different values:

```text
local values
preview values
production values
```

This prepares the project for GitOps because Argo CD can read the Helm chart from Git and render it automatically.

Without Helm, later phases would need to manage many duplicated Kubernetes YAML files.

---

## Phase 3 outcome

At the end of Phase 3, the project can claim:

```text
Packaged a FastAPI/PostgreSQL application as a Helm chart with environment-specific values, Kubernetes probes, services, secrets, PostgreSQL StatefulSet storage, local chart validation, and smoke-test based deployment verification.
```

Phase 3 created the foundation needed for Phase 4 Argo CD GitOps.
