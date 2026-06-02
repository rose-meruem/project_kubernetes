# Evidence — Phase 4 Argo CD Self-Healing

## Purpose

This evidence file records the GitOps self-healing validation performed in Phase 4.

The goal was to prove that Argo CD detects manual cluster drift and restores the Git-defined desired state.

## Initial state

```text
Deployment:       url-shortener 1/1 available
Argo CD sync:     Synced
Application:      Functionally healthy
Smoke test:       Passing
```

## Manual drift

The live Deployment was manually scaled to zero replicas:

```bash
kubectl scale deployment/url-shortener -n url-shortener --replicas=0
```

Immediate result:

```text
url-shortener   0/0   0   0
```

At this point, the live cluster state no longer matched the desired state stored in Git.

## Argo CD reconciliation

The Deployment was watched:

```bash
kubectl get deploy url-shortener -n url-shortener -w
```

Observed result:

```text
url-shortener   0/0   0   0
url-shortener   0/1   0   0
url-shortener   0/1   1   0
url-shortener   1/1   1   1
```

Argo CD events showed:

```text
Updated sync status: Synced -> OutOfSync
Updated sync status: OutOfSync -> Synced
Sync operation succeeded
```

## Post-reconciliation validation

After Argo CD restored the desired state:

```text
Deployment:       1/1 available
API pod:          1/1 Running
PostgreSQL pod:   1/1 Running
Smoke test:       Passed
```

Validation command:

```bash
make gitops-test
```

## Conclusion

Argo CD successfully detected manual drift and reconciled the cluster back to the Git-defined desired state.

This proves the core GitOps behavior required for Phase 4.
