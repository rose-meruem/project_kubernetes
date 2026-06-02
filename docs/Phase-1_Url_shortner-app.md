# Phase 1 — URL Shortener App

## Goal

Build a real application before adding Kubernetes.

This phase provides a small backend workload that can later be deployed with Helm, tested in k3d, exposed through PR preview environments, monitored, and used for incident simulations.

## What was built

A FastAPI URL shortener backed by PostgreSQL.

The app can:

- create a short code for a URL
- retrieve the original URL from the short code
- count link accesses
- expose health and readiness endpoints
- run locally with Docker Compose
- pass automated tests and smoke tests

## Runtime architecture

```text
Docker Compose
├── url-shortener-api       FastAPI app on port 8000
└── url-shortener-postgres  PostgreSQL on port 5432
```

## Main files

```text
app/
├── main.py
├── database.py
├── models.py
├── schemas.py
├── settings.py
├── requirements.txt
├── Dockerfile
└── tests/
    ├── test_health.py
    ├── test_ready.py
    └── test_links.py

docker-compose.yml
scripts/smoke-test.sh
evidence/command-outputs/
```

## API endpoints

| Endpoint | Purpose |
|---|---|
| `GET /health` | Confirms the API process is alive |
| `GET /ready` | Confirms PostgreSQL is reachable |
| `POST /links` | Creates a short link |
| `GET /links/{code}` | Retrieves the original URL and records one access |
| `GET /links/{code}/stats` | Returns the access count |

## Validation commands

Start the stack:

```bash
docker compose up -d --build
```

Check containers:

```bash
docker compose ps
```

Expected result:

```text
url-shortener-api        Up
url-shortener-postgres   Up (healthy)
```

Check health:

```bash
curl http://localhost:8000/health
```

Expected:

```json
{"status":"ok"}
```

Check readiness:

```bash
curl http://localhost:8000/ready
```

Expected:

```json
{"status":"ok","db":"reachable"}
```

Create a link:

```bash
curl -X POST http://localhost:8000/links \
  -H "Content-Type: application/json" \
  -d '{"original_url":"https://example.com"}'
```

Example output:

```json
{"code":"39O36S","original_url":"https://example.com/"}
```

Retrieve the link:

```bash
curl http://localhost:8000/links/39O36S
```

Check stats:

```bash
curl http://localhost:8000/links/39O36S/stats
```

Expected after one retrieval:

```json
{"code":"39O36S","accesses":1}
```

## Tests

Run:

```bash
docker compose exec api pytest -q
```

Validated result:

```text
3 passed
```

The tests cover:

- `/health`
- `/ready`
- link creation
- link retrieval
- access statistics

## Smoke test

Run:

```bash
./scripts/smoke-test.sh
```

Validated result:

```text
Smoke test passed
```

The smoke test checks the full runtime path:

```text
/health → /ready → POST /links → GET /links/{code} → /stats
```

## Evidence captured

```text
evidence/command-outputs/docker/phase-1-compose-ps.txt
evidence/command-outputs/api/phase-1-health.txt
evidence/command-outputs/api/phase-1-ready.txt
evidence/command-outputs/tests/phase-1-smoke-test.txt
evidence/command-outputs/tests/phase-1-pytest.txt
```

## Final status

```text
Phase 1: COMPLETE
```

Completed criteria:

- Docker Compose build works
- API container runs
- PostgreSQL is healthy
- health/readiness endpoints work
- URL shortener behavior works
- smoke test passes
- pytest passes
- evidence is captured

## Next phase

```text
Phase 2 — Local Golden Path with Makefile and k3d
```
