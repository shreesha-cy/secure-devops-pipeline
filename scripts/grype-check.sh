#!/bin/bash

THRESHOLD=7.0

# Count vulnerabilities with CVSS >= threshold
COUNT=$(jq '[.matches[] | select(.vulnerability.cvss != null) | select(.vulnerability.cvss[]?.metrics.baseScore >= '"$THRESHOLD"')] | length' grype-report.json)

echo "High/Critical vulnerabilities count: $COUNT"

if [ "$COUNT" -gt 0 ]; then
  echo "❌ Pipeline FAILED due to high vulnerabilities"
  exit 1
else
  echo "✅ Pipeline PASSED (No high/critical vulnerabilities)"
fi
