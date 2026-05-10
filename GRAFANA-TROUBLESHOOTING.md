# ❌ Grafana Data Pipeline Issues - Complete Analysis

## 🔍 Root Causes Found

Your Grafana dashboards are empty because **the data pipeline is incomplete**. Here's what's missing:

---

## 📋 Missing Components & Fixes

### **Issue #1: Missing Prometheus Pushgateway Service** ⚠️ CRITICAL
**Location:** `docker/monitoring/docker-compose.yml`

The Pushgateway is the entry point for metrics from your GitHub Actions pipeline. Without it, the pipeline can't send metrics anywhere.

**Fix:** Add this service to your docker-compose.yml:

```yaml
  # 📤 PROMETHEUS PUSHGATEWAY - Accepts metrics from CI/CD pipeline
  pushgateway:
    image: prom/pushgateway:latest
    container_name: prometheus-pushgateway
    ports:
      - "9091:9091"
    restart: unless-stopped
    networks:
      - monitoring
    volumes:
      - pushgateway_data:/prometheus
```

Also add to the `volumes:` section at the bottom:
```yaml
  pushgateway_data:
```

---

### **Issue #2: Missing Prometheus Scrape Config for Pushgateway** ⚠️ CRITICAL
**Location:** `docker/monitoring/prometheus.yml`

Prometheus doesn't know to scrape metrics from the Pushgateway.

**Fix:** Add this to your `scrape_configs:` section:

```yaml
  # 📤 Prometheus Pushgateway (receives metrics from CI/CD pipeline)
  - job_name: 'pushgateway'
    honor_labels: true
    static_configs:
      - targets: ['pushgateway:9091']
    scrape_interval: 10s
```

---

### **Issue #3: Missing Metrics Push Step in GitHub Actions Pipeline** ⚠️ CRITICAL
**Location:** `.github/workflows/pipeline.yml`

The pipeline runs security scans but **never sends the results to Prometheus**. The metrics script exists (`scripts/prometheus-metrics.sh`) but is never called.

**Fix:** Add this step at the end of your pipeline (after DefectDojo upload):

```yaml
      - name: 📊 Push Metrics to Prometheus Pushgateway
        if: always()
        continue-on-error: true
        run: |
          chmod +x ./scripts/prometheus-metrics.sh
          ./scripts/prometheus-metrics.sh \
            --pushgateway "${{ secrets.PUSHGATEWAY_URL }}" \
            --job "secure_devops_pipeline"
```

---

### **Issue #4: Missing Required GitHub Secrets** ⚠️ CRITICAL
**Location:** GitHub Repository → Settings → Secrets and Variables → Actions

Add these secrets to enable the full data pipeline:

| Secret Name | Value | Purpose |
|------------|-------|---------|
| `DOCKER_USERNAME` | Your DockerHub username | Push Docker images |
| `DOCKER_PASSWORD` | Your DockerHub password/token | Push Docker images |
| `SONAR_TOKEN` | SonarQube API token | SonarQube authentication |
| `NVD_API_KEY` | NVD API key from NIST | OWASP Dependency Check |
| `DEFECTDOJO_URL` | `http://host.docker.internal:8000` | DefectDojo API endpoint |
| `DEFECTDOJO_API_KEY` | DefectDojo API token | DefectDojo authentication |
| **`PUSHGATEWAY_URL`** | **`http://localhost:9091`** | **← THIS IS NEW** |

---

### **Issue #5: Prometheus Service Configuration**
**Location:** `docker/monitoring/prometheus.yml`

The current config is incomplete. The Spring Boot actuator target uses `host.docker.internal:8080` which won't have metrics running.

**Fix:** Ensure your `scrape_configs` contains exactly one entry for the pushgateway and one for prometheus:

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']
```

*(You can remove the spring-actuator config since that's optional)*

---

### **Issue #6: Grafana Datasource Not Preconfigured** ⚠️ MEDIUM
**Location:** Grafana UI needs manual setup

When Grafana starts, it doesn't automatically have Prometheus configured as a datasource.

**Fix:** Manually configure (1-time setup):

1. Open Grafana: http://localhost:3000
2. Login with `admin/admin`
3. Go: **Settings** (gear icon, bottom left) → **Data sources**
4. Click **Add data source**
5. Select **Prometheus**
6. Set URL to: `http://prometheus:9090`
7. Click **Save & Test**

---

### **Issue #7: Grafana Dashboards Not Importing Automatically** ⚠️ MEDIUM
**Location:** Grafana provisioning

Grafana doesn't auto-import the dashboard JSON files.

**Fix (Option A - Manual):**

1. Open Grafana: http://localhost:3000
2. Click **+** (top left) → **Import**
3. Click **Upload JSON file**
4. Select each dashboard:
   - `grafana-dashboards/01-pipeline-health.json`
   - `grafana-dashboards/02-findings-summary.json`
   - `grafana-dashboards/03-mttd-tracking.json`

**Fix (Option B - Automatic via Docker):**

Add provisioning to docker-compose.yml:

```yaml
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana-dashboards:/etc/grafana/provisioning/dashboards  # ADD THIS
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning  # ADD THIS
    ports:
      - "3000:3000"
    restart: unless-stopped
    depends_on:
      - prometheus
    networks:
      - monitoring
```

Also add provisioning config file at `docker/monitoring/grafana-dashboards-provisioning.yaml`:

```yaml
apiVersion: 1

providers:
  - name: 'Dashboard Provisioning'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

---

### **Issue #8: DefectDojo Prometheus Export Not Enabled** ⚠️ LOW
**Location:** `docker/monitoring/docker-compose.yml` - DefectDojo service

DefectDojo has a built-in Prometheus exporter that's disabled by default.

**Optional Fix** (if you want DefectDojo metrics):

Add to DefectDojo environment variables:

```yaml
      - DD_ENABLE_PROMETHEUS_EXPORT=True
```

Then add to `prometheus.yml`:

```yaml
  - job_name: 'defectdojo'
    static_configs:
      - targets: ['defectdojo:8000']
    scrape_interval: 30s
```

---

## 🚀 Implementation Checklist

Follow this order to set up the complete pipeline:

- [ ] **Step 1:** Update `docker/monitoring/docker-compose.yml` - Add Pushgateway service
- [ ] **Step 2:** Update `docker/monitoring/prometheus.yml` - Add Pushgateway scrape config
- [ ] **Step 3:** Update `.github/workflows/pipeline.yml` - Add metrics push step
- [ ] **Step 4:** Add GitHub Secrets (especially `PUSHGATEWAY_URL`)
- [ ] **Step 5:** Restart Docker services: `docker-compose -f docker/monitoring/docker-compose.yml down && docker-compose -f docker/monitoring/docker-compose.yml up -d`
- [ ] **Step 6:** Manually configure Grafana datasource (one-time)
- [ ] **Step 7:** Import Grafana dashboards
- [ ] **Step 8:** Trigger a pipeline run and verify data flows

---

## 🧪 Data Flow Verification

After implementing fixes, verify the pipeline:

### Step 1: Check Pushgateway is running
```bash
curl http://localhost:9091/metrics
```
Should show `push_time_seconds` and other metrics.

### Step 2: Check Prometheus scrapes Pushgateway
Open http://localhost:9090 → **Status** → **Targets**
Should show `pushgateway` job with status **UP**

### Step 3: Query Prometheus
In http://localhost:9090 → **Graph**, run:
```promql
up{job="pushgateway"}
```
Should return `1`

### Step 4: Trigger Pipeline Run
Push code to `main` branch, wait for GitHub Actions to complete.

### Step 5: Check Grafana Dashboards
Open http://localhost:3000, dashboards should now show data.

---

## 🔒 GitHub Secrets Setup

Go to: **Settings** → **Secrets and variables** → **Actions**

Add these secrets:

```
DOCKER_USERNAME=<your-dockerhub-username>
DOCKER_PASSWORD=<your-dockerhub-password>
SONAR_TOKEN=<generated-from-sonarqube>
NVD_API_KEY=<api-key-from-nist-nvd>
DEFECTDOJO_URL=http://host.docker.internal:8000
DEFECTDOJO_API_KEY=<generated-from-defectdojo>
PUSHGATEWAY_URL=http://localhost:9091
```

---

## 📊 Expected Metrics in Grafana

Once the pipeline is complete, you'll see:

### Dashboard 1: Pipeline Health
- Total pipeline runs
- Success rate
- Pipeline duration
- Failed stages

### Dashboard 2: Security Findings
- Vulnerabilities by tool (Trivy, Checkov, OWASP, etc.)
- Severity distribution (CRITICAL, HIGH, MEDIUM, LOW)
- Findings over time

### Dashboard 3: MTTD Tracking
- Mean Time To Detect
- Detection speed trends
- Stage performance

---

## ⚠️ Common Issues & Solutions

### "No data to display" in Grafana
1. Check Pushgateway is running: `curl http://localhost:9091/metrics`
2. Check Prometheus datasource: http://localhost:3000 → Settings → Data sources
3. Query test metric: In Prometheus, run `up` and verify results
4. Trigger a pipeline run: Push to main branch

### Prometheus shows "DOWN" for pushgateway
1. Verify service is running: `docker ps | grep pushgateway`
2. Check network: `docker network inspect monitoring`
3. Restart services: `docker-compose down && docker-compose up -d`

### Grafana dashboards are blank
1. Verify Prometheus datasource is set to `http://prometheus:9090`
2. Wait 2-3 minutes for Prometheus to scrape first batch
3. Manually import dashboard JSONs if auto-provisioning failed
4. Check browser console for errors

### DefectDojo shows data but Grafana doesn't
1. **This is expected!** DefectDojo metrics are separate from pipeline metrics
2. Pipeline metrics come from `prometheus-metrics.sh` script
3. DefectDojo metrics only appear if you enable `DD_ENABLE_PROMETHEUS_EXPORT=True`

---

## 📞 Quick Reference

| Component | Port | URL |
|-----------|------|-----|
| Prometheus | 9090 | http://localhost:9090 |
| Pushgateway | 9091 | http://localhost:9091 |
| Grafana | 3000 | http://localhost:3000 |
| DefectDojo | 8000 | http://localhost:8000 |
| SonarQube | 9000 | http://localhost:9000 |

---

## 🎯 Next Steps

1. **Read the fixes above carefully**
2. **Implement all 8 issues** (Critical fixes first)
3. **Add all GitHub secrets**
4. **Restart Docker services**
5. **Trigger a pipeline run**
6. **Monitor Prometheus and Grafana**

Need help? Check the `DEMO-CHECKLIST.md` for step-by-step demo walkthrough.
