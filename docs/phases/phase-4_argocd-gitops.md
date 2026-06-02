# Phase 4 — Argo CD GitOps

## Status

Phase 4 is functionally complete.

The URL shortener Helm chart is now deployed through Argo CD from the GitHub repository instead of being deployed only through manual `helm upgrade --install`.

Current result:

```text
GitHub repository
→ Argo CD Application
→ Helm chart rendering
→ Kubernetes resources in url-shortener namespace
→ Application smoke test
```

---

## Goal

The goal of Phase 4 was to move from manual Helm deployment to GitOps.

Before Phase 4:

```text
Developer runs helm upgrade --install manually
```

After Phase 4:

```text
Git repository is the desired state
Argo CD reads the repository
Argo CD reconciles the cluster state
Manual drift is detected and corrected
```

---

## Argo CD installation

Argo CD was installed in the `argocd` namespace.

Commands used:

```bash
kubectl create namespace argocd

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

During the first install, the `applicationsets.argoproj.io` CRD failed with:

```text
metadata.annotations: Too long: may not be more than 262144 bytes
```

This was caused by client-side apply storing a large manifest in the
`kubectl.kubernetes.io/last-applied-configuration` annotation.

The issue was fixed with server-side apply:

```bash
kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

CRDs after the fix:

```text
applications.argoproj.io
applicationsets.argoproj.io
appprojects.argoproj.io
```

Argo CD pods were running:

```text
argocd-application-controller       1/1 Running
argocd-applicationset-controller    1/1 Running
argocd-dex-server                   1/1 Running
argocd-notifications-controller     1/1 Running
argocd-redis                        1/1 Running
argocd-repo-server                  1/1 Running
argocd-server                       1/1 Running
```

---

## GitHub repository and SSH setup

A GitHub repository was created:

```text
git@github.com:rose-meruem/project_kubernetes.git
```

SSH authentication was configured and validated:

```bash
ssh -T git@github.com
```

Successful result:

```text
Hi rose-meruem! You've successfully authenticated, but GitHub does not provide shell access.
```

The local repository remote was updated to SSH:

```bash
git remote set-url origin git@github.com:rose-meruem/project_kubernetes.git
```

Remote verification:

```text
origin  git@github.com:rose-meruem/project_kubernetes.git (fetch)
origin  git@github.com:rose-meruem/project_kubernetes.git (push)
```

The local `main` branch was pushed to GitHub.

---

## Argo CD Application

The Argo CD Application manifest was created at:

```text
k8s/argocd/app-url-shortener.yaml
```

Manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: url-shortener
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/rose-meruem/project_kubernetes.git
    targetRevision: main
    path: charts/url-shortener
    helm:
      valueFiles:
        - values-local.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: url-shortener

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

The manifest was committed and pushed, then applied:

```bash
kubectl apply -f k8s/argocd/app-url-shortener.yaml
```

Argo CD status:

```text
NAME            SYNC STATUS   HEALTH STATUS
url-shortener   Synced        Progressing
```

The `Synced` state confirms that Argo CD successfully read the GitHub repository and applied the Helm chart.

---

## Runtime validation

The application resources were running correctly:

```text
url-shortener pod:          1/1 Running
url-shortener-postgres-0:   1/1 Running
Deployment:                 1/1 available
StatefulSet:                1/1 ready
```

Smoke test result:

```text
[1/5] Checking /health
{"status":"ok"}

[2/5] Checking /ready
{"status":"ok","db":"reachable"}

[3/5] Creating short link
{"code":"kvoQ56","original_url":"https://example.com/"}

[4/5] Fetching link stats
{"code":"kvoQ56","accesses":0}

[5/5] Smoke test completed successfully
```

---

## GitOps validation target

A `gitops-test` target was added to the `Makefile`.

Purpose:

```text
Validate that Argo CD has synced the application,
that Kubernetes workloads are running,
and that the application still passes smoke tests.
```

Relevant targets:

```makefile
argocd-status:
	kubectl get applications -n argocd
	kubectl describe application $(APP_NAME) -n argocd

argocd-check:
	kubectl wait application/$(APP_NAME) \
		-n argocd \
		--for=jsonpath='{.status.sync.status}'=Synced \
		--timeout=120s
	kubectl get application $(APP_NAME) -n argocd

gitops-test:
	$(MAKE) argocd-check
	kubectl get pods -n $(NAMESPACE)
	kubectl get deploy -n $(NAMESPACE)
	kubectl get statefulset -n $(NAMESPACE)
	$(MAKE) smoke-test
```

Validation command:

```bash
make gitops-test
```

Result:

```text
application.argoproj.io/url-shortener condition met

NAME            SYNC STATUS   HEALTH STATUS
url-shortener   Synced        Progressing

url-shortener pod:          1/1 Running
url-shortener-postgres-0:   1/1 Running
Deployment:                 1/1 available
StatefulSet:                1/1 ready
Smoke test:                 completed successfully
```

---

## Self-healing drift test

A manual drift test was performed to prove Argo CD reconciliation.

The live deployment was manually scaled to zero replicas:

```bash
kubectl scale deployment/url-shortener -n url-shortener --replicas=0
```

Immediate result:

```text
url-shortener   0/0   0   0
```

Argo CD detected drift and restored the Git-defined state:

```text
url-shortener   0/1   0   0
url-shortener   0/1   1   0
url-shortener   1/1   1   1
```

Argo CD events confirmed the reconciliation:

```text
Updated sync status: Synced -> OutOfSync
Updated sync status: OutOfSync -> Synced
Sync operation ... succeeded
```

After reconciliation:

```text
Deployment:   1/1 available
Pod:          1/1 Running
Smoke test:   completed successfully
```

This proves:

```text
manual cluster drift
→ Argo CD detects OutOfSync state
→ Argo CD reconciles the deployment
→ application returns to desired state
```

---

## Note about Argo CD health status

Argo CD still reports:

```text
Health Status: Progressing
```

The application itself is healthy. The likely cause is the local Ingress object having no address:

```text
NAME            CLASS     HOSTS       ADDRESS   PORTS
url-shortener   traefik   localhost             80
```

In this local environment, the empty Ingress address is acceptable for now because:

```text
Argo CD sync:      Synced
Deployment:        1/1 available
StatefulSet:       1/1 ready
/health:           OK
/ready:            OK, database reachable
Smoke test:        Passed
Self-healing:      Passed
```

This can be revisited later when moving to AWS, where ingress will be backed by AWS load balancing.

---

## Phase 4 outcome

At the end of Phase 4, the project can now claim:

```text
Implemented GitOps delivery with Argo CD for a Helm-packaged FastAPI/PostgreSQL application, enabling automated sync, pruning, self-healing, and drift correction validation on Kubernetes.
```

Phase 4 is complete from a functional DevOps/SRE perspective.
