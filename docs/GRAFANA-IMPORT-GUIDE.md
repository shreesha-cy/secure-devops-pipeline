# Grafana Dashboards Import Guide

## 📊 Three Dashboards Created

1. **Pipeline Health KPIs** - `01-pipeline-health.json`
   - Total pipeline runs
   - Success rate (7-day)
   - Average pipeline duration
   - Top failing stages

2. **Security Findings Summary** - `02-findings-summary.json`
   - Findings by tool (SAST, DAST, SCA, etc.)
   - Severity distribution (CRITICAL, HIGH, MEDIUM, LOW)
   - CVSS score distribution
   - Findings trend over 30 days

3. **MTTD & Performance Tracking** - `03-mttd-tracking.json`
   - Mean Time To Detect (MTTD)
   - Fastest/Slowest detection times
   - MTTD stability (variance)
   - Detection time by stage
   - Finding detection rate

---

## 🚀 Import Dashboards into Grafana

### **Method 1: Import via UI (Recommended)**

1. Open **Grafana**: http://localhost:3000
2. Login with `admin/admin`
3. Click **+** (top left) → **Import**
4. Click **Upload JSON file**
5. Select each file:
   - `01-pipeline-health.json`
   - `02-findings-summary.json`
   - `03-mttd-tracking.json`
6. For each import:
   - **Select Prometheus** as the data source
   - Click **Import**

### **Method 2: Import via URL (if hosted)**

1. In Grafana: **+** → **Import**
2. Paste the JSON content directly in the text box
3. Click **Load**
4. Select **Prometheus** datasource
5. Click **Import**

### **Method 3: CLI (Advanced)**

```bash
# Navigate to Grafana dashboards directory
cd secure-devops-pipeline/grafana-dashboards

# Import each dashboard using curl
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

for file in *.json; do
  curl -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d @"$file"
  echo "Imported $file"
done
```

---

## 📌 After Import - Important Setup

### **1. Verify Prometheus Datasource**

1. Go to **Settings** (gear icon, bottom left)
2. Click **Data sources**
3. Verify **Prometheus** exists and points to: `http://prometheus:9090`
4. If missing, click **Add data source**:
   - **Name**: Prometheus
   - **Type**: Prometheus
   - **URL**: http://prometheus:9090
   - Click **Save & Test**

### **2. Verify Metrics Are Flowing**

The dashboards will be empty until Prometheus collects metrics from DefectDojo.

**Check if Prometheus is scraping DefectDojo:**
1. Go to **Prometheus**: http://localhost:9090
2. Click **Status** → **Targets**
3. Look for `defectdojo` job
4. If "DOWN", verify DefectDojo is running: `docker-compose ps`

**Query a test metric in Prometheus:**
1. Click **Graph** in Prometheus
2. Enter: `up` (to see all targets)
3. Click **Execute**
4. Should show: `up{job="prometheus"} 1`

---

## 📊 Dashboard Descriptions

### **Dashboard 1: Pipeline Health KPIs**

**Purpose**: Monitor pipeline execution and health

**Key Metrics**:
- `sdop_pipeline_runs_total` - Total pipeline executions
- `sdop_pipeline_success_total` - Successful pipeline runs
- `sdop_pipeline_duration_seconds` - Time to execute pipeline
- `sdop_stage_failures_total` - Failures per stage

**Use Case**: Detect pipeline flakiness, performance degradation, and identify problematic stages

---

### **Dashboard 2: Security Findings Summary**

**Purpose**: Track security vulnerabilities discovered by all tools

**Key Metrics**:
- `dd_findings_by_tool` - Findings per security tool
- `dd_findings_by_severity` - Distribution by CVSS severity
- `dd_findings_by_cvss` - Findings grouped by CVSS score ranges
- `dd_findings_total` - Total cumulative findings
- `dd_findings_critical_total`, `dd_findings_high_total`, etc. - Counts by severity

**Use Case**: Understand security posture, track vulnerability trends, identify high-risk areas

---

### **Dashboard 3: MTTD & Performance Tracking**

**Purpose**: Measure detection speed and pipeline performance

**Key Metrics**:
- `sdop_mttd_seconds` - Mean time from commit to first detection
- `sdop_stage_duration_seconds` - How long each stage takes
- `sdop_findings_detected_total` - Rate of new findings detected

**Use Case**: Track improvement in detection speed, identify bottlenecks, measure shift-left effectiveness

---

## 🔧 Customizing Dashboards

### **Change Refresh Rate**

1. Click dashboard name (top left)
2. Click **Settings** (gear icon)
3. Under "Refresh", select interval (e.g., "30s", "1m")
4. Click **Save**

### **Add New Panel**

1. Click **+** → **Panel**
2. Enter PromQL query (examples below)
3. Click **Apply**

### **Example PromQL Queries**

```promql
# Pipeline pass rate over time
rate(sdop_pipeline_success_total[1h])

# Average stage duration
avg by (stage) (sdop_stage_duration_seconds)

# Critical vulnerabilities
sum(dd_findings_critical_total)

# Top 5 slowest stages
topk(5, max by (stage) (sdop_stage_duration_seconds))
```

---

## ✅ Verification Checklist

- [ ] All 3 dashboards imported into Grafana
- [ ] Prometheus datasource configured
- [ ] Can see "up" metric in Prometheus
- [ ] DefectDojo metrics being scraped
- [ ] Dashboard refresh set to 30s-1m
- [ ] Can access all 3 dashboards from Grafana home

---

## 📍 Dashboard Locations in Grafana

Once imported, access them from:
1. **Home** (top left) → Look for "SDOP-2025" dashboards
2. Or search by **UID**:
   - `sdop-pipeline-health`
   - `sdop-findings-summary`
   - `sdop-mttd-tracking`

---

## 🐛 Troubleshooting

### **Dashboards Show "No Data"**

**Cause**: Metrics not yet collected (pipeline hasn't run yet)

**Solution**:
1. Run the GitHub Actions pipeline: push code to trigger it
2. Wait 1-2 minutes for metrics to appear
3. Refresh dashboard (Ctrl+Shift+R)

### **"Prometheus Data Source Not Found"**

**Solution**:
1. Go to Grafana **Settings** → **Data sources**
2. Add Prometheus: http://prometheus:9090
3. Click **Save & Test**
4. Re-import dashboards

### **DefectDojo Not Showing Data**

**Solution**:
1. Verify DefectDojo is running: `docker-compose ps`
2. Check Prometheus config includes DefectDojo: `docker/monitoring/prometheus.yml`
3. Restart Prometheus: `docker-compose restart prometheus`

---

## 📝 Next Steps

1. ✅ Import all 3 dashboards
2. ⏭️ Run GitHub Actions pipeline (commit & push)
3. ⏭️ Wait for metrics to populate
4. ⏭️ View live dashboards
5. ⏭️ Share with faculty guide for project demo

