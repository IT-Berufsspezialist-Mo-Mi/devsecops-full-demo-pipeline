#!/usr/bin/env bash

set -e

URL="$1"

if [ -z "$URL" ]; then
  echo "Usage: ./smoke.sh <url>"
  exit 1
fi

echo "Running smoke test for: $URL"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

echo "HTTP status: $STATUS"

if [ "$STATUS" -ne 200 ]; then
  echo "Smoke test FAILED"
  exit 1
fi

echo "Smoke test PASSED"