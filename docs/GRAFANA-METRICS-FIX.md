# Grafana Metrics Issue - Root Cause & Fixes

## Summary

The Grafana dashboard was showing **NO DATA** despite successful builds and DefectDojo receiving updates. This document explains the root causes and the fixes applied.

---

## Root Cause Analysis

### Issue 1: Duplicate Prometheus Metric Headers ❌ CRITICAL

**The Problem**:
```
⚠️  Push returned HTTP 400
   Response: text format parsing error in line 4: second HELP line for metric name "pipeline_trivy_vulnerabilities_total"
```

The `prometheus-metrics.sh` script was adding HELP and TYPE lines **multiple times** for the same metric:

```prometheus
# HELP pipeline_trivy_vulnerabilities_total Total vulnerabilities...
# TYPE pipeline_trivy_vulnerabilities_total gauge
pipeline_trivy_vulnerabilities_total{severity="critical"} 5
# HELP pipeline_trivy_vulnerabilities_total Total vulnerabilities...  ❌ DUPLICATE!
# TYPE pipeline_trivy_vulnerabilities_total gauge                     ❌ DUPLICATE!
pipeline_trivy_vulnerabilities_total{severity="high"} 10
```

**Why This Fails**:
Prometheus text format (OpenMetrics) requires:
- Exactly **ONE** HELP line per metric name
- Exactly **ONE** TYPE line per metric name
- Multiple values are distinguished by **labels**, not by repeating headers

**Impact**:
- Prometheus Pushgateway rejects the metrics with HTTP 400
- Metrics never reach Prometheus
- Grafana has no data to display
- DefectDojo works because it receives raw reports directly (not affected by format)

### Issue 2: Missing GitHub Secrets ❌ CRITICAL

**The Problem**:
```bash
PUSHGATEWAY_URL=""          # Empty! Should come from secrets
AUTH=""                     # Empty! Should come from secrets
```

The script had empty hardcoded variables that should be using GitHub secrets:
- `PUSHGATEWAY_URL` - Prometheus Pushgateway endpoint (required)
- `PUSHGATEWAY_AUTH` - Basic auth credentials if Pushgateway requires it (optional)

**Why This Fails**:
- Script fails validation because `PUSHGATEWAY_URL` is empty
- Even if it had a default, the environment secrets weren't being used

---

## Fixes Applied

### Fix 1: Restructured Metrics Format

**File**: `scripts/prometheus-metrics.sh`

**Changed**:
- Old: Appended HELP/TYPE lines with every `add_metric()` call → Duplicates
- New: Store HELP/TYPE once per metric, collect all values separately

**Implementation**:
```bash
declare -A HELP_TEXT       # Stores HELP text (only once per metric)
declare -a METRIC_LINES    # Stores all metric lines

add_metric() {
  local NAME="$1"
  
  # Only add HELP and TYPE ONCE per metric name
  if [[ -z "${HELP_TEXT[$NAME]}" ]]; then
    HELP_TEXT[$NAME]="# HELP ${NAME} ${HELP}
# TYPE ${NAME} ${TYPE}"
  fi
  
  # Collect metric values separately
  METRIC_LINES+=("${NAME}{${LABELS}} ${VALUE}")
}
```

**Result**:
```prometheus
# HELP pipeline_trivy_vulnerabilities_total Total vulnerabilities...
# TYPE pipeline_trivy_vulnerabilities_total gauge
pipeline_trivy_vulnerabilities_total{severity="critical"} 5
pipeline_trivy_vulnerabilities_total{severity="high"} 10
pipeline_trivy_vulnerabilities_total{severity="medium"} 15
pipeline_trivy_vulnerabilities_total{severity="low"} 20
```

### Fix 2: Environment Variables & GitHub Secrets

**File**: `scripts/prometheus-metrics.sh`

**Changed**:
```bash
# OLD - Empty hardcoded values
PUSHGATEWAY_URL=""
AUTH=""

# NEW - Use environment variables from GitHub secrets, with CLI override
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-}"
AUTH="${PUSHGATEWAY_AUTH:-}"
```

**Enhanced Documentation**:
```bash
# Added comprehensive header comments:
# REQUIRED GITHUB SECRETS:
#   - PUSHGATEWAY_URL: URL to Prometheus Pushgateway
#   - PUSHGATEWAY_AUTH (optional): Basic auth credentials (format: username:password)
```

### Fix 3: Updated GitHub Workflow

**File**: `.github/workflows/pipeline.yml`

**Changed**:
```yaml
# OLD - Trying to pass via CLI (but secrets were empty)
./scripts/prometheus-metrics.sh \
  --pushgateway "${{ secrets.PUSHGATEWAY_URL }}" \
  --job "secure_devops_pipeline"

# NEW - Pass via environment variables (cleaner, supports fallbacks)
env:
  PUSHGATEWAY_URL: ${{ secrets.PUSHGATEWAY_URL }}
  PUSHGATEWAY_AUTH: ${{ secrets.PUSHGATEWAY_AUTH }}
run: |
  ./scripts/prometheus-metrics.sh \
    --job "secure_devops_pipeline"
```

### Fix 4: Enhanced Error Handling

**File**: `scripts/prometheus-metrics.sh`

**Changes**:
- Validates metrics format before pushing
- Saves metrics to `metrics-debug.txt` if push fails
- Provides detailed HTTP error responses
- Exits with error code on push failure (instead of `continue-on-error`)

```bash
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "202" ]]; then
  echo "✅ Metrics pushed successfully"
else
  echo "❌ Push failed with HTTP $HTTP_CODE"
  echo "   Response: $RESPONSE_BODY"
  # Save for debugging
  echo "$METRICS" > metrics-debug.txt
  exit 1
fi
```

### Fix 5: Configurable Threshold

**File**: `scripts/grype-check.sh`

**Changed**:
```bash
# OLD - Hardcoded
THRESHOLD=7.0

# NEW - Configurable via environment variable
THRESHOLD="${GRYPE_THRESHOLD:-7.0}"
```

---

## What You Need To Do

### Step 1: Set Up GitHub Secrets

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Add these secrets:

| Secret | Value | Required | Example |
|--------|-------|----------|---------|
| `PUSHGATEWAY_URL` | Prometheus Pushgateway endpoint | ✅ YES | `http://localhost:9091` |
| `PUSHGATEWAY_AUTH` | Basic auth (username:password) | ❌ Optional | `admin:password` |
| `DEFECTDOJO_URL` | DefectDojo server URL | ✅ YES | `http://localhost:8000` |
| `DEFECTDOJO_API_KEY` | DefectDojo API key | ✅ YES | `[your-api-key]` |
| `DOCKER_USERNAME` | Docker Hub username | ✅ YES | `your-username` |
| `DOCKER_PASSWORD` | Docker Hub token | ✅ YES | `[access-token]` |
| `SONAR_TOKEN` | SonarQube token | ❌ Optional | `[token]` |
| `NVD_API_KEY` | NVD API key | ❌ Optional | `[api-key]` |

**See**: [docs/GITHUB-SECRETS-SETUP.md](../docs/GITHUB-SECRETS-SETUP.md) for detailed instructions

### Step 2: Verify Your Setup

Test that Prometheus Pushgateway is reachable:

```bash
curl -X GET http://your-pushgateway-url:9091/api/v1/metrics/job/secure_devops_pipeline
```

Should return metrics in Prometheus format (not HTML).

### Step 3: Run a Test Build

Push to GitHub and trigger a new workflow run:

```bash
git add .
git commit -m "fix: prometheus metrics format and github secrets"
git push
```

**Check the workflow**:
1. Go to GitHub Actions
2. Wait for the "Push Metrics to Prometheus Pushgateway" step
3. Look for: `✅ Metrics pushed successfully (HTTP 202)`

### Step 4: Verify in Grafana

1. Log in to Grafana
2. Go to Explore → Select Prometheus data source
3. Query: `pipeline_trivy_vulnerabilities_total` 
4. Should see data points with different severity levels

---

## How to Debug If It Still Doesn't Work

### Debug Step 1: Check Metrics Format Locally

```bash
# After running the script, check the metrics file:
cat metrics-debug.txt | head -20

# Should see clean Prometheus format with no duplicate HELP lines:
# HELP pipeline_trivy_vulnerabilities_total ...
# TYPE pipeline_trivy_vulnerabilities_total gauge
pipeline_trivy_vulnerabilities_total{severity="critical"} X
pipeline_trivy_vulnerabilities_total{severity="high"} Y
```

### Debug Step 2: Validate Prometheus Format

```bash
# Use Prometheus text parser to validate
promtool check metrics metrics-debug.txt
```

### Debug Step 3: Check Pushgateway Directly

```bash
# See what metrics Pushgateway has for your job:
curl http://pushgateway:9091/metrics | grep secure_devops_pipeline
```

### Debug Step 4: Check Prometheus Scrape Configuration

Verify that Prometheus is configured to scrape Pushgateway:

```yaml
# In prometheus.yml:
scrape_configs:
  - job_name: 'pushgateway'
    static_configs:
      - targets: ['pushgateway:9091']
    honor_labels: true
```

### Debug Step 5: Check GitHub Secrets

Verify secrets are set:

```bash
# In workflow logs, the script should show:
echo "Pushgateway: $PUSHGATEWAY_URL"  # Should NOT be empty
echo "Auth: ***"                       # Should show *** if set
```

---

## Summary of Changes

| File | Change | Impact |
|------|--------|--------|
| `scripts/prometheus-metrics.sh` | Fixed duplicate HELP/TYPE lines | ✅ Metrics now accepted by Pushgateway |
| `scripts/prometheus-metrics.sh` | Added env var support for secrets | ✅ Uses GitHub secrets properly |
| `.github/workflows/pipeline.yml` | Pass secrets via env instead of CLI | ✅ Cleaner, more reliable |
| `scripts/grype-check.sh` | Made threshold configurable | ✅ Can adjust without code changes |
| `docs/GITHUB-SECRETS-SETUP.md` | New comprehensive guide | ✅ Easy setup instructions |

---

## Next Steps

1. ✅ Set up GitHub secrets (see GITHUB-SECRETS-SETUP.md)
2. ✅ Push the updated scripts to GitHub
3. ✅ Trigger a new workflow run
4. ✅ Verify metrics appear in Grafana
5. ✅ Create a Grafana dashboard with the metrics (see GRAFANA-IMPORT-GUIDE.md)

---

**Questions?** Check the troubleshooting section in [docs/GITHUB-SECRETS-SETUP.md](../docs/GITHUB-SECRETS-SETUP.md)
