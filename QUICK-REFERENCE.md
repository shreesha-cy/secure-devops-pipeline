# ⚡ QUICK REFERENCE - Exact URLs & Secrets

## Copy-Paste These Exact Values

### GitHub Secrets (Set These Now!)

```
1. PUSHGATEWAY_URL
   ┌────────────────────────────────┐
   │ http://localhost:9091          │  ← Copy this exactly
   └────────────────────────────────┘

2. DEFECTDOJO_URL
   ┌────────────────────────────────┐
   │ http://localhost:8000          │  ← Copy this exactly
   └────────────────────────────────┘

3. DEFECTDOJO_API_KEY
   ┌────────────────────────────────┐
   │ [your-api-key-from-defectdojo] │  ← Get from Settings
   └────────────────────────────────┘
```

---

## All URLs in Your Setup

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Pushgateway** | 9091 | `http://localhost:9091` | Receives metrics from GitHub |
| **Prometheus** | 9090 | `http://localhost:9090` | Stores & queries metrics |
| **Grafana** | 3000 | `http://localhost:3000` | Displays dashboards |
| **DefectDojo** | 8000 | `http://localhost:8000` | Vulnerability management |

---

## 3-Step Setup

### Step 1: Set Secrets in GitHub
```
Go to: GitHub → Settings → Secrets and variables → Actions
Add 3 secrets above ↑
```

### Step 2: Push Code
```bash
git add .
git commit -m "Set correct pushgateway URLs"
git push
```

### Step 3: Verify
```
1. Check workflow succeeds (GitHub Actions)
2. Query in Prometheus: http://localhost:9090/graph
   Search: pipeline_trivy_vulnerabilities_total
3. View in Grafana: http://localhost:3000
   Query the same metric
```

---

## Verify Connection Flow

```
1. Pushgateway Running?
   curl http://localhost:9091
   → Should show: HTML page (Pushgateway UI)

2. Prometheus Connected?
   curl http://localhost:9090
   → Should show: HTML page (Prometheus UI)

3. Can Prometheus reach Pushgateway?
   http://localhost:9090/targets
   → Pushgateway job should be: UP ✅

4. Can Grafana reach Prometheus?
   http://localhost:3000
   → Settings → Data Sources → Prometheus
   → Should be: Connected ✅

5. Metrics in Prometheus?
   http://localhost:9090/graph
   Query: pipeline_trivy_vulnerabilities_total
   → Should return: Data ✅

6. Metrics in Grafana?
   http://localhost:3000
   → Explore → Query: pipeline_trivy_vulnerabilities_total
   → Should show: Chart with data ✅
```

---

## What Each URL Does

**Pushgateway (`http://localhost:9091`)**
```
- GitHub Actions pushes metrics here
- Stores metrics temporarily
- Prometheus scrapes from here
- UI shows stored metrics
```

**Prometheus (`http://localhost:9090`)**
```
- Scrapes Pushgateway every 10 seconds
- Stores metrics in time-series database
- Allows querying metrics
- UI for manual queries & debugging
```

**Grafana (`http://localhost:3000`)**
```
- Connects to Prometheus as data source
- Creates dashboards
- Displays metrics in charts/gauges
- This is what end users see
```

**DefectDojo (`http://localhost:8000`)**
```
- Receives security findings
- Manages vulnerabilities
- Independent of metrics pipeline
- Works even if metrics are broken
```

---

## GitHub Secrets Mapping

```
GitHub Secret          →  Used By              →  Action
──────────────────────────────────────────────────────────
PUSHGATEWAY_URL       →  prometheus-metrics.sh →  Push metrics
DEFECTDOJO_URL        →  defectdojo-upload.sh →  Upload findings
DEFECTDOJO_API_KEY    →  defectdojo-upload.sh →  Authenticate
DOCKER_USERNAME       →  workflow              →  Push image
DOCKER_PASSWORD       →  workflow              →  Push image
```

---

## Exact Secret Values for YOUR Setup

```
⚠️  IMPORTANT: These are EXACT values for your local setup

PUSHGATEWAY_URL = http://localhost:9091
  - NOT: http://pushgateway:9091 (wrong - only works inside docker)
  - NOT: https://localhost:9091 (wrong - must be http)
  - NOT: localhost:9091 (wrong - missing http://)

DEFECTDOJO_URL = http://localhost:8000
  - NOT: http://localhost:8080 (wrong port)
  - NOT: https://localhost:8000 (wrong - use http)
  - NOT: localhost:8000 (wrong - missing http://)
```

---

## Troubleshooting Quick Fixes

| Problem | Fix |
|---------|-----|
| **Grafana shows no data** | Check: PUSHGATEWAY_URL secret is set to `http://localhost:9091` |
| **HTTP 400 error in workflow** | Check: Latest prometheus-metrics.sh (format fix applied) |
| **HTTP 401 error** | Check: Add PUSHGATEWAY_AUTH if Pushgateway requires auth |
| **Prometheus shows "DOWN"** | Wait 10s or restart: `docker-compose restart prometheus` |
| **DefectDojo API fails** | Check: DEFECTDOJO_API_KEY is valid (regenerate in DefectDojo) |

---

## Docker Containers Must Be Running

```bash
# Check status
docker ps

# Should see:
- prometheus (port 9090)
- grafana (port 3000)
- prometheus-pushgateway (port 9091)
- defectdojo-django (port 8000)

# Start all
cd docker/monitoring
docker-compose up -d
```

---

## Test URLs You Can Open in Browser

```
✅ Pushgateway:   http://localhost:9091
✅ Prometheus:    http://localhost:9090
✅ Grafana:       http://localhost:3000
✅ DefectDojo:    http://localhost:8000
```

**Try opening all 4 in browser to verify they're running!**

---

## One-Command Diagnostic

```bash
bash scripts/diagnose-metrics.sh
```

This automatically tests all connections and URLs!

---

## Still Stuck?

**Run this and share output:**

```bash
echo "=== PUSHGATEWAY ===" && curl http://localhost:9091
echo "=== PROMETHEUS ===" && curl http://localhost:9090
echo "=== TARGETS ===" && curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
echo "=== DOCKER ===" && docker ps -a
```

---

**Document:**
- Exact URLs: [URLS-AND-SECRETS-EXACT.md](URLS-AND-SECRETS-EXACT.md)
- Connection Diagram: [METRICS-CONNECTION-DIAGRAM.md](METRICS-CONNECTION-DIAGRAM.md)
- Full Troubleshooting: [STEP-BY-STEP-TROUBLESHOOTING.md](STEP-BY-STEP-TROUBLESHOOTING.md)

---

🎯 **Your Mission:**
1. Set 3 GitHub secrets with URLs above
2. Run: `git push`
3. Check workflow succeeds
4. Open: `http://localhost:3000`
5. Query: `pipeline_trivy_vulnerabilities_total`
6. See data! 📊
