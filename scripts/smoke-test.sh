#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-url-shortener}"
SERVICE="${SERVICE:-url-shortener}"
LOCAL_PORT="${LOCAL_PORT:-8081}"
REMOTE_PORT="${REMOTE_PORT:-8000}"
BASE_URL="${BASE_URL:-http://localhost:${LOCAL_PORT}}"

echo "[0/5] Starting port-forward svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT}"
kubectl port-forward -n "$NAMESPACE" "svc/${SERVICE}" "${LOCAL_PORT}:${REMOTE_PORT}" >/tmp/url-shortener-port-forward.log 2>&1 &
PF_PID=$!

cleanup() {
  kill "$PF_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

sleep 3

echo "[1/5] Checking /health"
curl -fsS "$BASE_URL/health"
echo

echo "[2/5] Checking /ready"
curl -fsS "$BASE_URL/ready"
echo

echo "[3/5] Creating short link"
CREATE_RESPONSE="$(curl -fsS -X POST "$BASE_URL/links" \
  -H "Content-Type: application/json" \
  -d '{"original_url":"https://example.com"}')"

echo "$CREATE_RESPONSE"

CODE="$(echo "$CREATE_RESPONSE" | python3 -c 'import sys,json; data=json.load(sys.stdin); print(data.get("code") or data.get("short_code") or "")')"

if [ -z "$CODE" ]; then
  echo "ERROR: Could not extract short code from response"
  exit 1
fi

echo "[4/5] Fetching link stats"
curl -fsS "$BASE_URL/links/$CODE/stats"
echo

echo "[5/5] Smoke test completed successfully"
