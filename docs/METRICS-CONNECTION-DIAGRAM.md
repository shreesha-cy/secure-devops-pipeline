# Metrics Pipeline - Connection Diagram

## Complete Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS                           │
│           (Self-Hosted Runner on Your Machine)              │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  │ 1. Run security scans
                  ▼
    ┌─────────────────────────────────┐
    │   Security Scans Generate       │
    │   - Trivy report (JSON)         │
    │   - Checkov report (JSON)       │
    │   - OWASP report (XML)          │
    └─────────────────┬───────────────┘
                      │
                      │ 2. Parse & Format
                      ▼
    ┌─────────────────────────────────┐
    │   prometheus-metrics.sh         │
    │   Converts to Prometheus format │
    │   (with HELP + TYPE headers)    │
    └─────────────────┬───────────────┘
                      │
                      │ 3. Push metrics
                      │ Uses: PUSHGATEWAY_URL
                      │       http://localhost:9091
                      ▼
    ╔═════════════════════════════════╗
    ║   PROMETHEUS PUSHGATEWAY        ║ ← Port 9091
    ║   prometheus-pushgateway        ║
    ║   (Stores metrics temporarily)  ║
    ╚═════════════════┬═══════════════╝
                      │
                      │ 4. Prometheus scrapes
                      │ (every 10 seconds)
                      │ Configured in: prometheus.yml
                      ▼
    ╔═════════════════════════════════╗
    ║   PROMETHEUS SERVER             ║ ← Port 9090
    ║   prom/prometheus:latest        ║
    ║   (Stores time-series metrics)  ║
    ╚═════════════════┬═══════════════╝
                      │
                      │ 5. Grafana queries
                      │ Every dashboard refresh
                      ▼
    ╔═════════════════════════════════╗
    ║   GRAFANA DASHBOARD             ║ ← Port 3000
    ║   grafana/grafana:latest        ║
    ║   📊 Displays metrics!          ║
    ╚═════════════════════════════════╝
```

---

## Network Connections

```
Your Machine
│
├─ GitHub Actions (Self-Hosted Runner)
│  │
│  └─ Calls prometheus-metrics.sh
│     └─ Pushes to: http://localhost:9091 ✅
│        (Uses PUSHGATEWAY_URL secret)
│
├─ Docker Containers (All on same network)
│  │
│  ├─ Prometheus (port 9090)
│  │  └─ Scrapes Pushgateway (http://pushgateway:9091)
│  │     Configured in prometheus.yml
│  │
│  ├─ Pushgateway (port 9091) ← Receives metrics from GitHub
│  │  └─ Stores metrics temporarily
│  │
│  └─ Grafana (port 3000)
│     └─ Queries Prometheus (http://prometheus:9090)
│        └─ Displays in dashboards
│
└─ Your Browser
   ├─ http://localhost:3000 → Grafana ✅
   ├─ http://localhost:9090 → Prometheus ✅
   └─ http://localhost:9091 → Pushgateway ✅
```

---

## URLs at Each Stage

```
┌──────────────────────────────────────────────────────┐
│ GITHUB ACTIONS (needs to connect to Pushgateway)    │
│                                                      │
│ Endpoint: http://localhost:9091 ✅                 │
│ Stored in secret: PUSHGATEWAY_URL                  │
│ Used by: prometheus-metrics.sh                     │
│ Method: curl --data-binary @- "$PUSHGATEWAY_URL"   │
└──────────────────────────────────────────────────────┘

        ↓ (HTTP POST with metrics)

┌──────────────────────────────────────────────────────┐
│ PROMETHEUS.YML (Prometheus config)                   │
│                                                      │
│ Scrape Target: http://pushgateway:9091 ✅          │
│ Note: Uses Docker internal name "pushgateway"       │
│ Why: Prometheus runs inside Docker container        │
│ Interval: 10 seconds (scrape_interval)              │
└──────────────────────────────────────────────────────┘

        ↓ (Prometheus reads metrics every 10s)

┌──────────────────────────────────────────────────────┐
│ PROMETHEUS SERVER (stores metrics)                   │
│                                                      │
│ URL: http://localhost:9090 ✅                       │
│ Data Source URL (from Grafana): http://prometheus   │
│ Note: Grafana connects to "prometheus" (Docker      │
│       internal name) not "localhost"                │
└──────────────────────────────────────────────────────┘

        ↓ (Grafana queries Prometheus)

┌──────────────────────────────────────────────────────┐
│ GRAFANA DASHBOARD (displays data)                   │
│                                                      │
│ URL: http://localhost:3000 ✅                       │
│ Query: SELECT pipeline_trivy_vulnerabilities_total  │
│ Result: Shows metrics in charts/gauges              │
└──────────────────────────────────────────────────────┘
```

---

## Key Point: Docker Network vs Local Machine

```
FROM GITHUB ACTIONS RUNNER:
  - Must use: http://localhost:9091 ✅
  - Cannot use: http://pushgateway:9091 ❌
    (pushgateway is Docker internal name, not accessible from host)

FROM DOCKER CONTAINERS (Prometheus, Grafana):
  - Must use: http://pushgateway:9091 ✅
    (internal Docker network)
  - Cannot use: http://localhost:9091 ❌
    (localhost inside container = container itself)
```

---

## Configuration Files & URLs

### 1. GitHub Secrets (you set these)
```
PUSHGATEWAY_URL = http://localhost:9091 ✅
```

### 2. Workflow File (.github/workflows/pipeline.yml)
```yaml
env:
  PUSHGATEWAY_URL: ${{ secrets.PUSHGATEWAY_URL }}  # http://localhost:9091
```

### 3. Script (scripts/prometheus-metrics.sh)
```bash
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-}"  # Gets from env var
PUSH_URL="$PUSHGATEWAY_URL/metrics/job/$JOB_NAME/..."
```

### 4. Prometheus Config (docker/monitoring/prometheus.yml)
```yaml
scrape_configs:
  - job_name: 'pushgateway'
    static_configs:
      - targets: ['pushgateway:9091']  # Uses Docker internal name
    scrape_interval: 10s
```

### 5. Docker Compose (docker/monitoring/docker-compose.yml)
```yaml
pushgateway:
  image: prom/pushgateway:latest
  container_name: prometheus-pushgateway
  ports:
    - "9091:9091"  # Exposes port 9091 to host machine
```

---

## Verification Checklist

```
✅ STEP 1: Docker Running
   docker ps | grep pushgateway
   → Should show: prometheus-pushgateway container running

✅ STEP 2: Pushgateway Accessible
   curl http://localhost:9091
   → Should show HTML page

✅ STEP 3: GitHub Secrets Set
   PUSHGATEWAY_URL = http://localhost:9091
   DEFECTDOJO_URL = http://localhost:8000

✅ STEP 4: Prometheus Scrapes Pushgateway
   http://localhost:9090/targets
   → Should show: job_name "pushgateway" with status "UP"

✅ STEP 5: Metrics Appear in Prometheus
   http://localhost:9090
   → Query: pipeline_trivy_vulnerabilities_total
   → Should return: Results with values

✅ STEP 6: Grafana Connects to Prometheus
   http://localhost:3000
   → Data Sources → Prometheus → Status: "Connected"

✅ STEP 7: Grafana Displays Metrics
   Create dashboard or query
   → Should display metric data
```

---

## Common Connection Issues & Fixes

### Issue: Prometheus shows "DOWN" for Pushgateway
```
❌ Problem: http://localhost:9091 doesn't work inside Docker
✅ Solution: prometheus.yml uses http://pushgateway:9091 (internal name)
```

### Issue: Grafana can't reach Prometheus
```
❌ Problem: Grafana data source configured as http://localhost:9090
✅ Solution: Use http://prometheus:9090 (Docker internal name)
```

### Issue: GitHub Actions can't reach Pushgateway
```
❌ Problem: Using http://pushgateway:9091 from GitHub runner
✅ Solution: Use http://localhost:9091 (set in PUSHGATEWAY_URL secret)
```

### Issue: Metrics not appearing in Grafana
```
❌ Problem: Pushgateway URL is http://pushgateway:9091 (wrong for GitHub)
❌ Problem: Prometheus not scraping Pushgateway (check targets)
❌ Problem: Prometheus has no Grafana data source connection

✅ Solution: Check all 3 connections above
```

---

## Quick Test Flow

```
1. Set GitHub Secrets
   ↓
2. Run: git push
   ↓
3. GitHub Actions runs
   ↓
4. Metrics script pushes to http://localhost:9091
   ↓
5. Check Prometheus targets (should be UP)
   ↓
6. Query Prometheus directly
   ↓
7. Check Grafana data source
   ↓
8. Query in Grafana dashboards
```

---

**For detailed troubleshooting:**

Run: `bash scripts/diagnose-metrics.sh`

This will test each connection in the pipeline! 🔍
