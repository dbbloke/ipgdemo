#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: smoke-test.sh [options] <url>

Options:
  -e <status>     Expected HTTP status code (default: 200)
  -m <substring>  Case-insensitive substring expected in the response body
                  (default: "hello")
  -t <seconds>    Overall curl timeout in seconds (default: 10)
  -r <count>      Number of retry attempts for transient failures (default: 3)
  -d <seconds>    Delay in seconds between retries (default: 2)
  -h              Show this help message

Set -m "" to skip body content verification.
USAGE
}

expected_status=200
expected_substring="hello"
timeout=10
retries=3
retry_delay=2

while getopts ":e:m:t:r:d:h" opt; do
  case "$opt" in
    e)
      expected_status="${OPTARG}"
      ;;
    m)
      expected_substring="${OPTARG}"
      ;;
    t)
      timeout="${OPTARG}"
      ;;
    r)
      retries="${OPTARG}"
      ;;
    d)
      retry_delay="${OPTARG}"
      ;;
    h)
      usage
      exit 0
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      usage
      exit 1
      ;;
    ?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

URL="${1:-}"

if [[ -z "$URL" ]]; then
  echo "A URL to probe is required." >&2
  usage
  exit 1
fi

if ! [[ "$expected_status" =~ ^[0-9]{3}$ ]]; then
  echo "Expected status must be a three-digit HTTP code." >&2
  exit 1
fi

if ! [[ "$timeout" =~ ^[0-9]+$ ]] || (( timeout <= 0 )); then
  echo "Timeout must be a positive integer (seconds)." >&2
  exit 1
fi

if ! [[ "$retries" =~ ^[0-9]+$ ]]; then
  echo "Retries must be a non-negative integer." >&2
  exit 1
fi

if ! [[ "$retry_delay" =~ ^[0-9]+$ ]]; then
  echo "Retry delay must be a non-negative integer (seconds)." >&2
  exit 1
fi

body_file=$(mktemp -t smoke-body.XXXXXX)
trap 'rm -f "$body_file"' EXIT

echo "Running smoke test against $URL (expecting HTTP ${expected_status})"

curl_args=(
  --silent
  --show-error
  --location
  --retry "${retries}"
  --retry-delay "${retry_delay}"
  --retry-all-errors
  --max-time "${timeout}"
  --output "$body_file"
  --write-out "%{http_code}"
  "$URL"
)

set +e
http_status=$(curl "${curl_args[@]}")
curl_exit=$?
set -e
http_status=${http_status//$'\n'/}

if [[ "$curl_exit" -ne 0 ]]; then
  echo "Smoke test failed: curl exited with status $curl_exit" >&2
  exit 2
fi

if [[ "$http_status" != "$expected_status" ]]; then
  echo "Smoke test failed: expected HTTP ${expected_status}, got ${http_status}" >&2
  cat "$body_file" >&2 || true
  exit 3
fi

if [[ -n "$expected_substring" ]]; then
  if ! grep -qiF "$expected_substring" "$body_file"; then
    echo "Smoke test failed: response body did not contain expected text: ${expected_substring}" >&2
    cat "$body_file" >&2 || true
    exit 4
  fi
fi

echo "Smoke test passed"
