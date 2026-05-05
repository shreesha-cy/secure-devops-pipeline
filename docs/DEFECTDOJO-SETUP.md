# DefectDojo Setup Guide for SDOP-2025

**DefectDojo** is the centralized vulnerability management platform aggregating findings from all security scanning tools (SAST, DAST, SCA, IaC, etc.).

---

## 🚀 Quick Start (5 Minutes)

### 1. Start the Stack
```bash
cd secure-devops-pipeline/docker/monitoring

# Start all services: Prometheus, Grafana, PostgreSQL, DefectDojo, Redis
docker-compose up -d

# Check status
docker-compose ps
```

**Expected output:**
```
CONTAINER ID   IMAGE                              STATUS
...
postgres        postgres:15-alpine                 Up (healthy)
defectdojo      defectdojo/defectdojo:latest       Up
redis           redis:7-alpine                     Up
prometheus      prom/prometheus:latest             Up
grafana         grafana/grafana:latest             Up
```

### 2. Wait for DefectDojo to Initialize
```bash
# Monitor startup logs
docker-compose logs -f defectdojo

# Wait until you see: "Starting development server at http://..."
# (Takes 60-90 seconds on first run)
```

### 3. Access DefectDojo
- **URL**: http://localhost:8000
- **Login**: 
  - Username: `admin`
  - Password: `admin123`

### 4. Generate API Token (for Pipeline Integration)
1. Log in to DefectDojo as `admin`
2. Navigate: **Admin** → **API Tokens**
3. Click **Add Token** (or generate from user profile)
4. **Copy the token** - you'll need this for GitHub secrets

---

## ⚙️ Configuration for SDOP-2025 Pipeline

### Step 1: Create an Engagement

An **Engagement** in DefectDojo is a container for all findings from a single pipeline run.

**Via UI:**
1. **Engagements** → **New Engagement**
2. Fill:
   - **Product**: Create new → `SDOP-2025`
   - **Engagement Name**: `SDOP-2025-Pipeline-Scan`
   - **Engagement Type**: `CI/CD`
   - **Status**: `Active`
   - **Target Start**: Today
   - **Target End**: Next week
3. **Save**
4. **Copy the Engagement ID** from the URL: `http://localhost:8000/engagement/<ENGAGEMENT_ID>/`

**Or via API:**
```bash
DEFECTDOJO_URL="http://localhost:8000"
API_TOKEN="<your_api_token>"

curl -X POST "$DEFECTDOJO_URL/api/v2/engagements/" \
  -H "Authorization: Token $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product": 1,
    "name": "SDOP-2025-Pipeline-Scan",
    "engagement_type": "CI/CD",
    "status": "Active"
  }' | jq .
```

### Step 2: Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```bash
DEFECTDOJO_URL=http://localhost:8000       # For local dev
DEFECTDOJO_API_KEY=<your_api_token>        # From Step 1
DEFECTDOJO_ENGAGEMENT_ID=<engagement_id>   # From Step 1
PUSHGATEWAY_URL=http://localhost:9091      # Prometheus Pushgateway (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

⚠️ **Note for Pipeline Testing**: If running locally, use `http://host.docker.internal:8000` instead of `localhost:8000` when calling from GitHub Actions runners.

### Step 3: Supported Scan Types

DefectDojo auto-maps these scan types from the pipeline:

| Tool | Scan Type (in API call) | Format | Priority |
|------|-------------------------|--------|----------|
| **Gitleaks** | `Gitleaks Scan` | JSON | High |
| **SonarQube** | `SonarQube Scan` | JSON | High |
| **Trivy** | `Trivy Scan` | JSON | High |
| **OWASP Dependency-Check** | `Dependency Check Scan` | XML | High |
| **OWASP ZAP** | `ZAP Scan` | JSON | High |
| **Grype** | `Grype Scan` | JSON | Medium |
| **Checkov** | `Checkov Scan` | JSON | Medium |

---

## 🔗 Integration with SDOP-2025 Pipeline

### Pipeline Auto-Upload Flow

The `.github/workflows/pipeline.yml` already contains DefectDojo integration:

```yaml
- name: Upload Reports to DefectDojo
  if: always()
  continue-on-error: true
  env:
    DD_URL: ${{ secrets.DEFECTDOJO_URL }}
    DD_API_KEY: ${{ secrets.DEFECTDOJO_API_KEY }}
    ENGAGEMENT_ID: ${{ secrets.DEFECTDOJO_ENGAGEMENT_ID }}
  run: |
    curl -X POST "$DD_URL/api/v2/import-scan/" \
      -H "Authorization: Token $DD_API_KEY" \
      -F "file=@<report_file>" \
      -F "scan_type=<Tool Name>" \
      -F "engagement=$ENGAGEMENT_ID"
```

### Manual Test Upload (Local)

Test that DefectDojo API is reachable:

```bash
DEFECTDOJO_URL="http://localhost:8000"
API_TOKEN="<your_api_token>"
ENGAGEMENT_ID="<your_engagement_id>"

# Create dummy scan report
cat > dummy-scan.json << 'EOF'
{
  "version": "2.4.0",
  "reportSchema": "1.0",
  "findings": [
    {
      "title": "Test Finding",
      "severity": "High",
      "description": "This is a test finding"
    }
  ]
}
EOF

# Upload test report
curl -X POST "$DEFECTDOJO_URL/api/v2/import-scan/" \
  -H "Authorization: Token $API_TOKEN" \
  -F "file=@dummy-scan.json" \
  -F "scan_type=Gitleaks Scan" \
  -F "engagement=$ENGAGEMENT_ID" \
  -v
```

**Expected Response**: `201 Created` with finding ID.

---

## 📊 Using DefectDojo

### View Findings
1. **Engagements** → Select `SDOP-2025-Pipeline-Scan`
2. **Findings** tab → See all uploaded vulnerabilities
3. Click a finding for details: CWE, CVSS, remediation guidance

### Track Remediation
1. Click finding → **Change Status** → `Verified`, `False Positive`, etc.
2. Add **Notes** (e.g., "Fixed in PR #123")
3. Findings persist across pipeline runs for tracking

### Generate Report
1. **Reports** → **New Report**
2. Select findings → Export as PDF/HTML
3. Use for security compliance documentation

### API Queries (for Grafana/Scripts)

Get finding summary:
```bash
curl -H "Authorization: Token $API_TOKEN" \
  "$DEFECTDOJO_URL/api/v2/findings/?engagement=$ENGAGEMENT_ID" | jq .
```

Get metrics:
```bash
curl -H "Authorization: Token $API_TOKEN" \
  "$DEFECTDOJO_URL/api/v2/dashboard/?engagement=$ENGAGEMENT_ID" | jq .
```

---

## 🐛 Troubleshooting

### DefectDojo Won't Start
```bash
# Check logs
docker-compose logs defectdojo

# Common issue: Port 8000 already in use
# Solution: Change port in docker-compose.yml: "8001:8000"
```

### Can't Connect to PostgreSQL
```bash
# Verify PostgreSQL is running and healthy
docker-compose exec postgres pg_isready -U defectdojo

# Reset data (WARNING: deletes all findings)
docker-compose down -v
docker-compose up -d
```

### API Token Not Working
```bash
# Get token from container
docker-compose exec defectdojo bash
python manage.py drf_create_token admin

# Or via UI: Admin → Tokens → Generate
```

### Pipeline Can't Reach DefectDojo
- Local machine: Use `http://localhost:8000`
- Docker container: Use `http://defectdojo:8000` (internal network)
- GitHub Actions: Use `http://host.docker.internal:8000` (if Docker Desktop) OR expose via ngrok/public IP

---

## 🔐 Security Notes (For Production)

- ✅ **DO**: Change default passwords in `docker-compose.yml`
- ✅ **DO**: Use HTTPS with reverse proxy (nginx)
- ✅ **DO**: Enable email notifications
- ✅ **DO**: Set up automated backups of PostgreSQL
- ⚠️ **DON'T**: Expose DefectDojo directly to internet without authentication
- ⚠️ **DON'T**: Commit API tokens to Git

---

## ✅ Verification Checklist

- [ ] `docker-compose ps` shows all 5 services running
- [ ] DefectDojo UI loads at http://localhost:8000
- [ ] Login successful with `admin/admin123`
- [ ] API token generated and copied
- [ ] Engagement created with ID noted
- [ ] GitHub secrets configured (DEFECTDOJO_URL, API_KEY, ENGAGEMENT_ID)
- [ ] Test upload successful (201 Created response)
- [ ] Findings visible in DefectDojo UI

---

## 📝 Next Steps

1. ✅ DefectDojo is running
2. ⏭️ Create Grafana dashboards (see `GRAFANA-DASHBOARDS.md`)
3. ⏭️ Test full pipeline integration (run GitHub Actions)
4. ⏭️ Enhance ZAP + Slack notifications .

