# Evidence — Phase 3 Smoke Test

## Purpose

This evidence file records the validation result for the Helm-based local deployment.

The goal was to prove that the Helm chart deploys a working FastAPI/PostgreSQL application on the local kind cluster.

## Validated components

```text
FastAPI Deployment:        1/1 available
PostgreSQL StatefulSet:    1/1 ready
/health endpoint:          OK
/ready endpoint:           OK, database reachable
POST /links:               OK
GET /links/{code}/stats:   OK
```

## Smoke test command

```bash
make smoke-test
```

## Expected result

```text
[0/5] Starting port-forward svc/url-shortener 8081:8000
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

## Conclusion

The application is deployable through Helm and passes runtime validation.
