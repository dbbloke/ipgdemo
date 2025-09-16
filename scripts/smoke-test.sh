#!/usr/bin/env bash
set -euo pipefail

URL="${1:-}"

if [[ -z "$URL" ]]; then
  echo "Usage: $0 <url>" >&2
  exit 1
fi

echo "Running smoke test against $URL"
response=$(curl -fsS -o /tmp/smoke-body.txt -w "%{http_code}" "$URL")

if [[ "$response" != "200" ]]; then
  echo "Smoke test failed: expected HTTP 200, got $response" >&2
  cat /tmp/smoke-body.txt >&2 || true
  exit 2
fi

grep -qi "hello" /tmp/smoke-body.txt || {
  echo "Smoke test failed: response body did not contain expected text" >&2
  exit 3
}

echo "Smoke test passed"
