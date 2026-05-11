# Step-by-Step: Get Grafana Metrics Working

Follow these exact steps to verify and fix your setup.

---

## Phase 1: Verify Docker Containers Are Running

### Step 1.1: Check All Containers
```bash
docker ps
```

**You should see:**
```
CONTAINER ID    IMAGE                            STATUS
xxx             prom/prometheus:latest           Up X minutes
xxx             grafana/grafana:latest           Up X minutes
xxx             prom/pushgateway:latest          Up X minutes
xxx             defectdojo/defectdojo-django     Up X minutes
xxx             postgres:15-alpine               Up X minutes
xxx             redis:7-alpine                   Up X minutes
```

**If any are missing or stopped:**
```bash
# Start all containers
cd docker/monitoring
docker-compose up -d

# Wait 10 seconds for services to start
sleep 10

# Check again
docker ps
```

### Step 1.2: Check Container Logs
```bash
# Check Prometheus for errors
docker logs prometheus | tail -20

# Check Pushgateway for errors
docker logs prometheus-pushgateway | tail -20

# Check Grafana for errors
docker logs grafana | tail -20
```

---

## Phase 2: Verify Network Connectivity (Localhost)

### Step 2.1: Test Pushgateway
```bash
curl -v http://localhost:9091
```

**Expected Output:**
```
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
...
<html>...Prometheus Pushgateway...</html>
```

### Step 2.2: Test Prometheus
```bash
curl -v http://localhost:9090
```

**Expected Output:**
```
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
...
<html>...Prometheus...</html>
```

### Step 2.3: Test Grafana
```bash
curl -v http://localhost:3000
```

**Expected Output:**
```
HTTP/1.1 302 Found
Location: http://localhost:3000/login
```

### If Any Test Fails:
```bash
# Check if ports are in use
netstat -tuln | grep -E "9090|9091|3000"

# Or using lsof (if available)
lsof -i :9091
lsof -i :9090
lsof -i :3000
```

---

## Phase 3: Verify Prometheus Configuration

### Step 3.1: Check Prometheus Targets
```
1. Open: http://localhost:9090
2. Click: "Status" → "Targets"
3. Look for: job_name "pushgateway"
4. Check Status: Should be "UP" (green)
```

**If Pushgateway target is DOWN:**
```bash
# Check Prometheus logs
docker logs prometheus | grep -i "pushgateway"

# Common issue: Prometheus can't reach http://pushgateway:9091
# Fix: docker logs will show the error
# Usually means container not in same network
```

### Step 3.2: View Prometheus Configuration
```
1. Open: http://localhost:9090
2. Click: "Status" → "Configuration"
3. Look for: scrape_configs section
4. Should have: job_name: 'pushgateway'
               targets: ['pushgateway:9091']
```

---

## Phase 4: Set GitHub Secrets

### Step 4.1: Get DefectDojo API Key

```bash
# Option 1: Use default credentials (if still set)
# Login to: http://localhost:8000
# Username: admin
# Password: admin123

# Option 2: Generate new API key in DefectDojo
# 1. Log in to http://localhost:8000
# 2. Click user icon (top right) → My Profile
# 3. Tab: "API Key"
# 4. Click "Generate" if needed
# 5. Copy the token value
```

### Step 4.2: Set GitHub Secrets

Go to: `GitHub → Repository → Settings → Secrets and variables → Actions`

**Add/Update these 3 secrets:**

```
Secret 1: PUSHGATEWAY_URL
Value: http://localhost:9091
Click: "Add secret"

Secret 2: DEFECTDOJO_URL  
Value: http://localhost:8000
Click: "Add secret"

Secret 3: DEFECTDOJO_API_KEY
Value: [paste-your-api-key-here]
Click: "Add secret"
```

**Optional Secrets:**
```
DOCKER_USERNAME = [your-docker-hub-username]
DOCKER_PASSWORD = [docker-hub-access-token]
```

### Step 4.3: Verify Secrets Are Set
```bash
# Check in GitHub UI
1. Go to Settings → Secrets
2. Should see:
   ✓ PUSHGATEWAY_URL
   ✓ DEFECTDOJO_URL
   ✓ DEFECTDOJO_API_KEY
   (values masked as ***)
```

---

## Phase 5: Test Metrics Push Manually

### Step 5.1: Create Test Metric
```bash
# Create a test metrics file
cat > /tmp/test-metrics.txt << 'EOF'
# HELP test_metric Test metric for debugging
# TYPE test_metric gauge
test_metric{label="test"} 42
EOF
```

### Step 5.2: Push to Pushgateway
```bash
curl -v --data-binary @/tmp/test-metrics.txt \
  http://localhost:9091/metrics/job/test_job
```

**Expected Output:**
```
HTTP/1.1 202 Accepted
```

**If you get HTTP 400:**
```
❌ Problem: Metrics format error
✅ Solution: Make sure metrics file is valid
```

### Step 5.3: Check Metrics Appear
```bash
# Option 1: View Pushgateway UI
# Open: http://localhost:9091
# Should see your metrics

# Option 2: Query metrics endpoint
curl http://localhost:9091/metrics | grep test_metric
```

---

## Phase 6: Run GitHub Workflow

### Step 6.1: Commit and Push Code
```bash
git add .
git commit -m "fix: prometheus metrics with correct urls"
git push
```

### Step 6.2: Monitor Workflow
```
1. Go to GitHub → Actions tab
2. Find your workflow run
3. Click to expand
4. Look for step: "Push Metrics to Prometheus Pushgateway"
```

### Step 6.3: Check for Success Message
**In workflow logs, look for:**
```
✅ Metrics pushed successfully (HTTP 202)
```

**If you see error:**
```
⚠️ Push returned HTTP 400
→ Check: prometheus-metrics.sh format (see METRICS-FORMAT-FIX.md)

⚠️ Error: PUSHGATEWAY_URL is required
→ Check: GitHub secrets are set correctly
```

### Step 6.4: Debug if Needed
```bash
# In GitHub workflow logs, you should see:
echo "Pushgateway: $PUSHGATEWAY_URL"  # Should show http://localhost:9091
echo "Auth: ***"                       # If auth set, shows ***
```

---

## Phase 7: Verify in Prometheus

### Step 7.1: Query Metrics
```
1. Open: http://localhost:9090
2. Click: "Graph" tab
3. In search box, type: pipeline_trivy_vulnerabilities_total
4. Click: "Execute"
```

**Expected Output:**
```
Table view shows multiple rows:
  pipeline_trivy_vulnerabilities_total{severity="critical"} X
  pipeline_trivy_vulnerabilities_total{severity="high"} Y
  ...
```

**If no results:**
```
❌ Metrics not in Prometheus yet
Reason 1: Pushgateway job shows DOWN (check Phase 3)
Reason 2: Prometheus not scraping yet (wait 10+ seconds)
Reason 3: Metrics not pushed (check GitHub workflow logs)
```

---

## Phase 8: Verify in Grafana

### Step 8.1: Check Data Source
```
1. Open: http://localhost:3000
2. Login: admin / admin
3. Go to: Settings (gear icon) → Data Sources
4. Click: "Prometheus"
5. Check: Status shows "Connected" (green checkmark)
```

**If not connected:**
```
❌ Problem: Wrong Prometheus URL
Fix: 
  1. Click "Edit"
  2. In "URL" field, set: http://prometheus:9090
     (not http://localhost:9090)
  3. Click "Save & Test"
  4. Should show "Data source is working"
```

### Step 8.2: Query Metrics in Explore
```
1. Go to: Explore (left sidebar)
2. In dropdown, select: "Prometheus"
3. In query box, type: pipeline_trivy_vulnerabilities_total
4. Click: Run query
```

**Expected Output:**
```
Time series graph showing:
  - X-axis: Time
  - Y-axis: Vulnerability count
  - Multiple lines for each severity level
```

---

## Phase 9: If Still No Data - Debug Checklist

```
❓ Is Prometheus running?
  → docker ps | grep prometheus

❓ Does Prometheus have Pushgateway target UP?
  → http://localhost:9090/targets
  
❓ Are metrics in Pushgateway?
  → curl http://localhost:9091/metrics

❓ Can Prometheus query metrics?
  → http://localhost:9090/graph
  → Query: up{job="pushgateway"}
  → Should return: up 1
  
❓ Can Prometheus scrape Pushgateway endpoint?
  → Check: http://localhost:9090/api/v1/targets
  → Look for health: "up" under job "pushgateway"
  
❓ Is Grafana connected to Prometheus?
  → http://localhost:3000
  → Settings → Data Sources → Prometheus
  → Should show green checkmark
  
❓ Did GitHub Actions actually push metrics?
  → Check: GitHub Actions workflow logs
  → Look for: "Metrics pushed successfully"
  
❓ Are GitHub secrets correct?
  → PUSHGATEWAY_URL = http://localhost:9091 ✅
  → DEFECTDOJO_URL = http://localhost:8000 ✅
```

---

## Final Verification - Complete Test

Run this command to test everything:

```bash
bash scripts/diagnose-metrics.sh
```

This will automatically:
- ✅ Test Pushgateway connectivity
- ✅ Test Prometheus connectivity
- ✅ Test Grafana connectivity
- ✅ Check Prometheus targets status
- ✅ Attempt a test metrics push
- ✅ Verify metrics appear in Prometheus
- ✅ List required GitHub secrets

---

## Still Not Working? Run These Debug Commands

```bash
# 1. Container Status
docker ps -a

# 2. Container Network
docker network ls
docker network inspect monitoring

# 3. Pushgateway Metrics
curl http://localhost:9091/metrics | head -30

# 4. Prometheus Targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets'

# 5. Prometheus Scrape Config
curl http://localhost:9090/api/v1/status/config | jq '.data.yaml'

# 6. Container Logs
docker logs prometheus 2>&1 | tail -30
docker logs prometheus-pushgateway 2>&1 | tail -30
docker logs grafana 2>&1 | tail -30

# 7. Port Status
ss -tuln | grep -E "9091|9090|3000"
```

---

## SUCCESS! 🎉

When everything is working, you should see:

```
✅ GitHub Secrets configured with correct URLs
✅ Workflow runs and shows "Metrics pushed successfully (HTTP 202)"
✅ Prometheus shows Pushgateway job as "UP"
✅ Prometheus contains metrics: pipeline_trivy_vulnerabilities_total
✅ Grafana Data Source connected to Prometheus
✅ Grafana dashboards display metrics 📊
```

**Next Steps:**
1. Create custom Grafana dashboards
2. Set up Prometheus alerts
3. Configure Grafana notifications
4. Monitor security metrics continuously

---

**Stuck?** Share the output of: `bash scripts/diagnose-metrics.sh`

We can diagnose the exact issue! 🔍
