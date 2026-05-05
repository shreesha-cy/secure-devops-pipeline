#!/bin/bash
# Prometheus Metrics Exporter for Secure DevOps Pipeline
# Parses security scan results and pushes metrics to Prometheus Pushgateway.
# Usage: prometheus-metrics.sh --pushgateway URL [--job NAME]

set -e

PUSHGATEWAY_URL=""
JOB_NAME="secure_devops_pipeline"
BUILD_NUMBER="${GITHUB_RUN_NUMBER:-0}"
REPO="${GITHUB_REPOSITORY:-unknown}"

usage() {
  echo "Usage: $0 --pushgateway <url> [--job <name>]"
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --pushgateway) PUSHGATEWAY_URL="$2"; shift ;;
    --job) JOB_NAME="$2"; shift ;;
    *) echo "Unknown parameter: $1"; usage ;;
  esac
  shift
done

if [[ -z "$PUSHGATEWAY_URL" ]]; then
  echo "❌ Error: --pushgateway is required"
  usage
fi

PUSH_URL="$PUSHGATEWAY_URL/metrics/job/$JOB_NAME/instance/build_${BUILD_NUMBER}"

echo "=================================================="
echo "📊 Prometheus Metrics Exporter"
echo "=================================================="
echo "Pushgateway: $PUSHGATEWAY_URL"
echo "Job: $JOB_NAME"
echo "Build: $BUILD_NUMBER"
echo ""

# Collect metrics into a variable
METRICS=""

add_metric() {
  local NAME="$1"
  local HELP="$2"
  local TYPE="$3"
  local VALUE="$4"
  local LABELS="${5:-}"

  if [[ -n "$LABELS" ]]; then
    METRICS+="# HELP ${NAME} ${HELP}
# TYPE ${NAME} ${TYPE}
${NAME}{${LABELS}} ${VALUE}
"
  else
    METRICS+="# HELP ${NAME} ${HELP}
# TYPE ${NAME} ${TYPE}
${NAME} ${VALUE}
"
  fi
}

# --- Trivy metrics ---
TRIVY_CRITICAL=0
TRIVY_HIGH=0
TRIVY_MEDIUM=0
TRIVY_LOW=0

if [[ -f "trivy-report.json" ]]; then
  echo "🔍 Parsing Trivy report..."
  TRIVY_CRITICAL=$(python3 -c "
import json, sys
try:
  d = json.load(open('trivy-report.json'))
  results = d.get('Results', [])
  count = sum(1 for r in results for v in r.get('Vulnerabilities', []) or [] if v.get('Severity') == 'CRITICAL')
  print(count)
except Exception as e:
  print(0)
" 2>/dev/null || echo "0")
  TRIVY_HIGH=$(python3 -c "
import json, sys
try:
  d = json.load(open('trivy-report.json'))
  results = d.get('Results', [])
  count = sum(1 for r in results for v in r.get('Vulnerabilities', []) or [] if v.get('Severity') == 'HIGH')
  print(count)
except Exception as e:
  print(0)
" 2>/dev/null || echo "0")
  TRIVY_MEDIUM=$(python3 -c "
import json, sys
try:
  d = json.load(open('trivy-report.json'))
  results = d.get('Results', [])
  count = sum(1 for r in results for v in r.get('Vulnerabilities', []) or [] if v.get('Severity') == 'MEDIUM')
  print(count)
except Exception as e:
  print(0)
" 2>/dev/null || echo "0")
  TRIVY_LOW=$(python3 -c "
import json, sys
try:
  d = json.load(open('trivy-report.json'))
  results = d.get('Results', [])
  count = sum(1 for r in results for v in r.get('Vulnerabilities', []) or [] if v.get('Severity') == 'LOW')
  print(count)
except Exception as e:
  print(0)
" 2>/dev/null || echo "0")
  echo "  CRITICAL=$TRIVY_CRITICAL HIGH=$TRIVY_HIGH MEDIUM=$TRIVY_MEDIUM LOW=$TRIVY_LOW"
else
  echo "⚠️  trivy-report.json not found, skipping Trivy metrics"
fi

add_metric "pipeline_trivy_vulnerabilities_total" "Total vulnerabilities found by Trivy" "gauge" "$TRIVY_CRITICAL" 'severity="critical"'
add_metric "pipeline_trivy_vulnerabilities_total" "Total vulnerabilities found by Trivy" "gauge" "$TRIVY_HIGH" 'severity="high"'
add_metric "pipeline_trivy_vulnerabilities_total" "Total vulnerabilities found by Trivy" "gauge" "$TRIVY_MEDIUM" 'severity="medium"'
add_metric "pipeline_trivy_vulnerabilities_total" "Total vulnerabilities found by Trivy" "gauge" "$TRIVY_LOW" 'severity="low"'

# --- Checkov metrics ---
CHECKOV_PASSED=0
CHECKOV_FAILED=0
CHECKOV_SKIPPED=0

if [[ -f "checkov-report.json" ]]; then
  echo "🔍 Parsing Checkov report..."
  CHECKOV_PASSED=$(python3 -c "
import json, sys
try:
  d = json.load(open('checkov-report.json'))
  if isinstance(d, list):
    print(sum(r.get('summary', {}).get('passed', 0) for r in d))
  else:
    print(d.get('summary', {}).get('passed', 0))
except Exception:
  print(0)
" 2>/dev/null || echo "0")
  CHECKOV_FAILED=$(python3 -c "
import json, sys
try:
  d = json.load(open('checkov-report.json'))
  if isinstance(d, list):
    print(sum(r.get('summary', {}).get('failed', 0) for r in d))
  else:
    print(d.get('summary', {}).get('failed', 0))
except Exception:
  print(0)
" 2>/dev/null || echo "0")
  CHECKOV_SKIPPED=$(python3 -c "
import json, sys
try:
  d = json.load(open('checkov-report.json'))
  if isinstance(d, list):
    print(sum(r.get('summary', {}).get('skipped', 0) for r in d))
  else:
    print(d.get('summary', {}).get('skipped', 0))
except Exception:
  print(0)
" 2>/dev/null || echo "0")
  echo "  PASSED=$CHECKOV_PASSED FAILED=$CHECKOV_FAILED SKIPPED=$CHECKOV_SKIPPED"
else
  echo "⚠️  checkov-report.json not found, skipping Checkov metrics"
fi

add_metric "pipeline_checkov_checks_total" "Total checks by Checkov" "gauge" "$CHECKOV_PASSED" 'result="passed"'
add_metric "pipeline_checkov_checks_total" "Total checks by Checkov" "gauge" "$CHECKOV_FAILED" 'result="failed"'
add_metric "pipeline_checkov_checks_total" "Total checks by Checkov" "gauge" "$CHECKOV_SKIPPED" 'result="skipped"'

# --- OWASP Dependency Check metrics ---
OWASP_VULN_COUNT=0

if [[ -f "app/target/dependency-check-report.xml" ]]; then
  echo "🔍 Parsing OWASP Dependency Check report..."
  OWASP_VULN_COUNT=$(python3 -c "
import xml.etree.ElementTree as ET, sys
try:
  tree = ET.parse('app/target/dependency-check-report.xml')
  root = tree.getroot()
  # Try default and namespace variants
  vulns = root.findall('.//vulnerability') or root.findall('.//{*}vulnerability')
  print(len(vulns))
except Exception as e:
  print(0)
" 2>/dev/null || echo "0")
  echo "  VULNERABILITIES=$OWASP_VULN_COUNT"
else
  echo "⚠️  dependency-check-report.xml not found, skipping OWASP metrics"
fi

add_metric "pipeline_owasp_vulnerabilities_total" "Total vulnerabilities found by OWASP Dependency Check" "gauge" "$OWASP_VULN_COUNT"

# --- Build metadata metric ---
add_metric "pipeline_build_info" "Build information" "gauge" "1" "repo=\"$REPO\",build=\"$BUILD_NUMBER\""

# --- Push metrics ---
echo ""
echo "📤 Pushing metrics to Pushgateway..."
PUSH_RESPONSE=$(echo "$METRICS" | curl -s -w "\n%{http_code}" --data-binary @- "$PUSH_URL")
HTTP_CODE=$(echo "$PUSH_RESPONSE" | tail -1)

if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "202" ]]; then
  echo "✅ Metrics pushed successfully (HTTP $HTTP_CODE)"
else
  echo "⚠️  Push returned HTTP $HTTP_CODE"
  echo "   Response: $(echo "$PUSH_RESPONSE" | head -n -1)"
fi

echo ""
echo "=================================================="
echo "📊 Metrics Summary"
echo "  Trivy:   CRITICAL=$TRIVY_CRITICAL HIGH=$TRIVY_HIGH MEDIUM=$TRIVY_MEDIUM LOW=$TRIVY_LOW"
echo "  Checkov: PASSED=$CHECKOV_PASSED FAILED=$CHECKOV_FAILED SKIPPED=$CHECKOV_SKIPPED"
echo "  OWASP:   VULNERABILITIES=$OWASP_VULN_COUNT"
echo "=================================================="
