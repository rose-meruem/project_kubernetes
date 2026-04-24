#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8000}"

echo "[1/5] Checking /health"
curl -fsS "$BASE_URL/health"

echo
echo "[2/5] Checking /ready"
curl -fsS "$BASE_URL/ready"

echo
echo "[3/5] Creating link"
CREATE_RESPONSE="$(curl -fsS -X POST "$BASE_URL/links" \
  -H "Content-Type: application/json" \
  -d '{"original_url":"https://example.com"}')"

echo "$CREATE_RESPONSE"

CODE="$(python -c 'import json,sys; print(json.load(sys.stdin)["code"])' <<< "$CREATE_RESPONSE")"

echo "[4/5] Retrieving link: $CODE"
curl -fsS "$BASE_URL/links/$CODE"

echo
echo "[5/5] Checking stats"
curl -fsS "$BASE_URL/links/$CODE/stats"

echo
echo "Smoke test passed"
