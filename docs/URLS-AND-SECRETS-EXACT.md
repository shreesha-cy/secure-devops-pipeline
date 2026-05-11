# GitHub Secrets - Exact URLs for Your Setup

## Your Current Docker Setup

Based on your `docker-compose.yml`:

```
📊 Prometheus:     http://localhost:9090    (port 9090)
📈 Grafana:        http://localhost:3000    (port 3000)
🗄️  DefectDojo:    http://localhost:8000    (port 8000)
📤 Pushgateway:    http://localhost:9091    (port 9091)
```

All containers run in Docker network named: `monitoring`

---

## GitHub Secrets - CORRECT Values

Since you're using a **self-hosted runner on the same machine**, the URLs should be:

### **REQUIRED - Set These Now**

```
1. PUSHGATEWAY_URL
   Value: http://localhost:9091
   
2. DEFECTDOJO_URL
   Value: http://localhost:8000

3. DEFECTDOJO_API_KEY
   Value: [Get from DefectDojo API settings]
```

### **OPTIONAL - For Authentication**

```
4. PUSHGATEWAY_AUTH
   Value: (leave empty if no auth required)
   
5. SONAR_TOKEN
   Value: (if using SonarQube)
```

---

## Step-by-Step Setup

### Step 1: Generate DefectDojo API Key

```bash
# 1. Access DefectDojo
# Open: http://localhost:8000
# Login with: admin / admin123

# 2. Go to: Settings → API Key
# 3. Click "Generate" if needed
# 4. Copy the API token value
```

### Step 2: Set GitHub Secrets

```
Go to: GitHub Repository
  → Settings 
    → Secrets and variables 
      → Actions
        → New repository secret
```

Add these 3 secrets:

**Secret 1:**
```
Name: PUSHGATEWAY_URL
Value: http://localhost:9091
```

**Secret 2:**
```
Name: DEFECTDOJO_URL
Value: http://localhost:8000
```

**Secret 3:**
```
Name: DEFECTDOJO_API_KEY
Value: [your-api-key-from-step-1]
```

### Step 3: Verify URLs in Workflow

The workflow should already have these configured correctly (we updated it):

```yaml
env:
  PUSHGATEWAY_URL: ${{ secrets.PUSHGATEWAY_URL }}
  PUSHGATEWAY_AUTH: ${{ secrets.PUSHGATEWAY_AUTH }}
```

---

## Verify Everything is Connected

### Test 1: Check Pushgateway is Running

```bash
# From your machine, test:
curl http://localhost:9091
# Should return HTML page (Pushgateway UI)
```

### Test 2: Check Prometheus Can See Pushgateway

```bash
# Open Prometheus:
# http://localhost:9090

# Go to: Status → Targets
# Look for: job_name: 'pushgateway'
# Should show: UP ✅ (not DOWN)
```

### Test 3: Check Grafana Can See Prometheus

```bash
# Open Grafana:
# http://localhost:3000
# Login: admin / admin

# Go to: Configuration → Data Sources
# Look for: Prometheus
# Should show: Connected (green checkmark)
```

### Test 4: Manually Test Metrics Push

```bash
# Simulate what GitHub Actions does:
cat > test-metrics.txt << 'EOF'
# HELP test_metric Test metric
# TYPE test_metric gauge
test_metric 42
EOF

# Push to pushgateway:
curl --data-binary @test-metrics.txt \
  http://localhost:9091/metrics/job/test_job

# Should return: HTTP 202 (Accepted)
```

### Test 5: Check Metrics Appear in Prometheus

```bash
# In Prometheus (http://localhost:9090)
# Go to: Graph
# Search for: test_metric
# Should see it! ✅
```

---

## The Complete Data Flow (Verified)

```
1. GitHub Actions (self-hosted runner)
   ↓
2. Runs security scans (Trivy, Checkov, etc.)
   ↓
3. Script pushes metrics to: http://localhost:9091/metrics/job/...
   ✅ Uses PUSHGATEWAY_URL secret
   ↓
4. Prometheus scrapes Pushgateway (every 10s)
   ✅ Configured in prometheus.yml
   ↓
5. Grafana queries Prometheus
   ✅ Displays metrics in dashboards
```

---

## If Grafana Still Shows No Data

### Checklist:

- [ ] PUSHGATEWAY_URL is set in GitHub secrets: `http://localhost:9091`
- [ ] DEFECTDOJO_URL is set in GitHub secrets: `http://localhost:8000`
- [ ] DEFECTDOJO_API_KEY is set in GitHub secrets
- [ ] Docker containers are running: `docker ps | grep -E "prometheus|grafana|pushgateway|defectdojo"`
- [ ] Pushgateway is responding: `curl http://localhost:9091`
- [ ] Prometheus shows "UP" for pushgateway job: `http://localhost:9090/status`
- [ ] Grafana data source is connected: `http://localhost:3000` (check Data Sources)

### Debug Commands:

```bash
# 1. Check all containers running
docker ps

# 2. Check pushgateway metrics
curl http://localhost:9091/metrics

# 3. Check prometheus targets
curl http://localhost:9090/api/v1/targets

# 4. Query prometheus for metrics
curl 'http://localhost:9090/api/v1/query?query=pipeline_trivy_vulnerabilities_total'

# 5. Check workflow logs in GitHub Actions
# Look for: "Pushgateway: http://localhost:9091"
# Should NOT be empty or "(nil)"
```

---

## Scripts Using These URLs

### `scripts/prometheus-metrics.sh`
```bash
# Gets URL from environment variable:
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-}"

# Uses it to build push URL:
PUSH_URL="$PUSHGATEWAY_URL/metrics/job/$JOB_NAME/instance/build_${BUILD_NUMBER}"

# Pushes metrics:
curl --data-binary @- "$PUSH_URL"
```

### `scripts/defectdojo-upload.sh`
```bash
# Gets URL from environment variable:
DEFECTDOJO_URL="${DEFECTDOJO_URL:-}"

# Uses it to upload findings:
curl "$DEFECTDOJO_URL/api/v2/findings/"
```

### `.github/workflows/pipeline.yml`
```yaml
# Passes secrets as environment variables:
env:
  PUSHGATEWAY_URL: ${{ secrets.PUSHGATEWAY_URL }}
  DEFECTDOJO_URL: ${{ secrets.DEFECTDOJO_URL }}
  DEFECTDOJO_API_KEY: ${{ secrets.DEFECTDOJO_API_KEY }}
```

---

## Network Configuration

### Inside Docker Network (container-to-container)
```
pushgateway container can reach: http://pushgateway:9091
prometheus container can reach: http://prometheus:9090
grafana container can reach: http://prometheus:9090
```

### From Self-Hosted Runner (on same machine)
```
Can use: http://localhost:9091
Or: http://127.0.0.1:9091
Or: http://[your-machine-ip]:9091
```

### GitHub Secrets (What We Use)
```
Use: http://localhost:9091
Why: Self-hosted runner runs on same machine as Docker
```

---

## Quick Reference Table

| Component | Port | Docker Internal URL | External URL (GitHub Secrets) |
|-----------|------|-------------------|-----|
| **Prometheus** | 9090 | http://prometheus:9090 | N/A (not pushed to) |
| **Pushgateway** | 9091 | http://pushgateway:9091 | **http://localhost:9091** ← USE THIS |
| **Grafana** | 3000 | http://grafana:3000 | http://localhost:3000 (browser) |
| **DefectDojo** | 8000 | http://defectdojo:8000 | **http://localhost:8000** ← USE THIS |
| **Prometheus.yml** | N/A | Uses Docker names | N/A |

---

## Common Mistakes to Avoid ❌

```
❌ WRONG:  http://pushgateway.com
❌ WRONG:  http://pushgateway:9091 (only works inside docker network)
❌ WRONG:  https://localhost:9091 (use http, not https)
❌ WRONG:  localhost:9091 (must include http://)
❌ WRONG:  Empty string "" (must set in GitHub secrets)

✅ CORRECT:  http://localhost:9091
✅ CORRECT:  http://127.0.0.1:9091
✅ CORRECT:  http://[your-ip]:9091 (if runner on different machine)
```

---

## After Setting Secrets - Run a Test

1. **Update secrets in GitHub**
2. **Push code:**
   ```bash
   git add .
   git commit -m "test: verify metrics with correct urls"
   git push
   ```
3. **Check workflow logs:**
   - Should show: `✅ Metrics pushed successfully (HTTP 202)`
4. **Verify in Prometheus:**
   - http://localhost:9090/targets
   - Pushgateway job should show: `UP`
5. **Verify in Grafana:**
   - Query: `pipeline_trivy_vulnerabilities_total`
   - Should return data!

---

**Is there a specific URL that's not working? Run these commands and share the output:**

```bash
echo "=== Pushgateway ==="
curl -v http://localhost:9091

echo ""
echo "=== Prometheus Targets ==="
curl http://localhost:9090/api/v1/targets

echo ""
echo "=== Prometheus Scrape Config ==="
curl http://localhost:9090/api/v1/status/config
```
