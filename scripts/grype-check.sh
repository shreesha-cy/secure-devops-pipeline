#!/bin/bash
# Grype Vulnerability Check Script
# 
# ENVIRONMENT VARIABLES:
#   - GRYPE_THRESHOLD: CVSS score threshold for HIGH/CRITICAL (default: 7.0)
#
# Exit codes:
#   - 0: No high vulnerabilities found
#   - 1: High vulnerabilities found or threshold exceeded

THRESHOLD="${GRYPE_THRESHOLD:-7.0}"

# Count vulnerabilities with CVSS >= threshold
COUNT=$(jq '[.matches[] | select(.vulnerability.cvss != null) | select(.vulnerability.cvss[]?.metrics.baseScore >= '"$THRESHOLD"')] | length' grype-report.json)

echo "High/Critical vulnerabilities count (CVSS >= $THRESHOLD): $COUNT"

if [ "$COUNT" -gt 0 ]; then
  echo "❌ Pipeline FAILED due to high vulnerabilities"
  exit 1
else
  echo "✅ Pipeline PASSED (No high/critical vulnerabilities)"
fi
