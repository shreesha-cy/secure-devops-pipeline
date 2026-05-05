# SDOP-2025 Full Pipeline Testing & Validation Guide

**Stage 7-8 Testing**: DAST (ZAP) + Reporting + Slack + DefectDojo Integration

---

## 📊 Testing Phases

### **Phase 1: Pre-Pipeline Setup** (5 min)
### **Phase 2: End-to-End Pipeline Test** (20-30 min)
### **Phase 3: Findings Validation** (10 min)
### **Phase 4: Reporting Verification** (5 min)

---

## ✅ Phase 1: Pre-Pipeline Setup

### **1.1 Verify All Services Running**

```bash
# Check DefectDojo stack
docker-compose -f docker/monitoring/docker-compose.yml ps

# Expected output:
# NAME                    STATUS      PORTS
# postgres                Up          5432/tcp
# redis                   Up          6379/tcp
# defectdojo-django       Up          8080/tcp
# defectdojo-nginx        Up          8000/tcp
# prometheus              Up          9090/tcp
# grafana                 Up          3000/tcp
```

**If any service is down**:
```bash
docker-compose -f docker/monitoring/docker-compose.yml restart <service-name>
```

### **1.2 Verify GitHub Secrets**

Ensure these secrets are set in your GitHub repo (Settings → Secrets and variables):

```
✅ DEFECTDOJO_URL = http://your-ip:8000
✅ DEFECTDOJO_API_KEY = <your-api-key-here>
✅ DEFECTDOJO_ENGAGEMENT_ID = 1
✅ SLACK_WEBHOOK_URL = https://hooks.slack.com/services/...
✅ PUSHGATEWAY_URL = http://your-ip:9091
✅ NVD_API_KEY = (if using OWASP Dependency Check)
✅ DOCKER_USERNAME = (if pushing to Docker Hub)
✅ DOCKER_PASSWORD = (if pushing to Docker Hub)
```

**Verify in terminal**:
```bash
# Clone repo (if needed)
git clone <repo-url>
cd secure-devops-pipeline

# View repo secrets (via gh CLI)
gh secret list

# Expected: All 8+ secrets listed
```

### **1.3 Verify ZAP Configuration**

```bash
# Check ZAP context file exists
ls -la zap/sdop-context.xml
# Output: -rw-r--r-- ... zap/sdop-context.xml

# Check enhanced pipeline
grep -A5 "OWASP ZAP Enhanced" .github/workflows/pipeline.yml
# Output: Should show new enhanced scan configuration
```

---

## 🚀 Phase 2: End-to-End Pipeline Test

### **2.1 Trigger Pipeline**

**Option A: Commit & Push**
```bash
# Make a small change to trigger pipeline
echo "# Pipeline Test $(date)" >> README.md

git add .
git commit -m "test: Trigger full pipeline for Stage 7-8 validation"
git push origin main
```

**Option B: Manual Trigger (if GitHub Actions allows)**
```bash
# In GitHub Actions UI:
# 1. Go to Actions tab
# 2. Select "SDOP-2025 Secure DevOps Pipeline" workflow
# 3. Click "Run workflow" → "Run workflow"
```

### **2.2 Monitor Pipeline Progress**

Open GitHub Actions in browser:
```
https://github.com/<your-username>/<repo>/actions
```

**Expected Timeline**:
```
⏱️ ~2-3 min  : Stage 1-2 (Secret + SAST)
⏱️ ~3-5 min  : Stage 3-4 (SCA + IaC)
⏱️ ~5-10 min : Stage 5-6 (Container + Policy)
⏱️ ~3-5 min  : Stage 7 (ZAP DAST) ← Your focus
⏱️ ~1-2 min  : Stage 8 (DefectDojo + Slack + Metrics)
═════════════════════════════════════
⏱️ ~20-30 min: TOTAL
```

### **2.3 Watch Stage 7 Execution**

In GitHub Actions, click on the ZAP step:

```
Step: OWASP ZAP Enhanced Active Scan (Stage 7)

Expected logs:
  ✅ Starting enhanced OWASP ZAP scan...
  ✅ Running baseline scan with active mode...
  ✅ ZAP scan exit code: 0
  ✅ ZAP report successfully generated
  📊 ZAP Findings:
     🔴 CRITICAL: 0
     🟠 HIGH:     0
  ✅ FR-11 COMPLIANT: No HIGH/CRITICAL findings
```

**If you see FAILURES**:
- ✅ 0 findings → Pipeline **continues** (good!)
- ❌ >0 HIGH/CRITICAL → Pipeline **fails** (FR-11 working!)
- ⚠️ Timeout → Increase timeout in pipeline.yml

### **2.4 Check Final Status**

After pipeline completes:

```bash
# Download artifacts
gh run download <RUN_ID> -D artifacts/

# View ZAP report
cat artifacts/sdop-security-reports/zap-report.json | jq '.'
```

---

## 📋 Phase 3: Findings Validation

### **3.1 Verify DefectDojo Received Findings**

Navigate to DefectDojo UI:
```
http://localhost:8000
Login: admin / admin123
```

**Path**: Engagements → SDOP-2025 → Findings

**Check**:
- [ ] New finding count increased (should show ZAP findings)
- [ ] Scan type: "ZAP Scan"
- [ ] Severity breakdown (CRITICAL, HIGH, MEDIUM, LOW)
- [ ] CVSS scores assigned
- [ ] Timestamp matches pipeline run time

### **3.2 Verify Grafana Dashboards Populated**

Navigate to Grafana:
```
http://localhost:3000
Login: admin / admin
```

**Check Dashboard 1: Pipeline Health**
- [ ] New pipeline run appears
- [ ] Success rate updated
- [ ] Pipeline duration recorded

**Check Dashboard 2: Findings Summary**
- [ ] Findings by tool shows ZAP data
- [ ] Severity distribution updated
- [ ] CVSS histogram visible

**Check Dashboard 3: MTTD Tracking**
- [ ] Detection times recorded
- [ ] Mean time to detect updated
- [ ] Stage-level timing visible

### **3.3 Verify Slack Notification**

Check your Slack channel:

**Expected message**:
```
✅ Pipeline success (or ❌ if findings)
   Branch: main
   Commit: abc1234
   DAST Findings:
      🔴 Critical: 0
      🟠 High: 2
   
   View in GitHub: [link]
```

**If not received**:
- Verify SLACK_WEBHOOK_URL secret is set
- Check Slack webhook URL is valid
- Review GitHub Actions logs for curl errors

---

## 🔍 Phase 4: Reporting Verification

### **4.1 Generate Security Report**

Create a summary of what was tested:

```bash
# Create report directory
mkdir -p reports/
cd reports/

# Copy ZAP findings
cp ../zap-report.json ./

# Generate summary
cat > STAGE-7-8-TEST-REPORT.md << 'EOF'
# Stage 7-8 Pipeline Test Report

## Test Date
$(date)

## Pipeline Status
- ✅ All 8 stages executed successfully
- ✅ ZAP DAST completed without errors
- ✅ DefectDojo integration verified
- ✅ Slack notifications sent
- ✅ Grafana dashboards updated

## Stage 7: DAST (OWASP ZAP)

### Findings Summary
EOF

# Add ZAP findings
jq '.site[0].alerts | group_by(.riskcode) | map({risk: .[0].riskcode, count: length})' zap-report.json >> STAGE-7-8-TEST-REPORT.md

echo "" >> STAGE-7-8-TEST-REPORT.md
cat >> STAGE-7-8-TEST-REPORT.md << 'EOF'

### FR-11 Compliance
✅ Any HIGH/CRITICAL findings properly block pipeline
✅ MEDIUM/LOW findings logged but don't block
✅ JSON report generated and uploaded to DefectDojo

## Stage 8: Reporting & Notifications

### DefectDojo Integration
✅ ZAP report uploaded to engagement ID: 1
✅ Findings imported and visible in UI
✅ Severity classification correct

### Grafana Dashboards
✅ Dashboard 1: Pipeline Health updated
✅ Dashboard 2: Findings Summary updated
✅ Dashboard 3: MTTD Tracking updated

### Slack Notifications
✅ Rich message format sent
✅ Findings count included
✅ Pipeline status emoji displayed

## Metrics Collected
- Pipeline duration: [auto-calculated]
- MTTD: Findings detection time
- Success rate: 1 run (100%)

## Next Steps
1. Continue monitoring dashboards for trend analysis
2. Address any HIGH/CRITICAL findings from other stages
3. Archive this test report for documentation
EOF

cat STAGE-7-8-TEST-REPORT.md
```

### **4.2 Create Final Verification Checklist**

```bash
cat > VERIFICATION-CHECKLIST.md << 'EOF'
# SDOP-2025 Stage 7-8 Verification Checklist

## Stage 7: OWASP ZAP DAST

- [ ] ZAP scan completed without errors
- [ ] Baseline scanning enabled (passive mode)
- [ ] JSON report generated: `zap-report.json`
- [ ] Report contains findings with severity levels
- [ ] Report uploaded to DefectDojo

### FR-11 Compliance (HIGH/CRITICAL block)
- [ ] Pipeline fails if HIGH findings > 0
- [ ] Pipeline fails if CRITICAL findings > 0
- [ ] Pipeline passes if only MEDIUM/LOW findings
- [ ] Error message includes finding counts
- [ ] Slack alert sent on failure

## Stage 8: Reporting & Integration

### DefectDojo
- [ ] API endpoint reachable (http://localhost:8000)
- [ ] Authentication working (admin/admin123)
- [ ] Engagement created: SDOP-2025
- [ ] ZAP findings imported
- [ ] Finding severity classification correct

### Grafana
- [ ] Prometheus datasource configured
- [ ] Dashboard 1 (Pipeline Health) visible
- [ ] Dashboard 2 (Findings Summary) visible
- [ ] Dashboard 3 (MTTD Tracking) visible
- [ ] Metrics updating from pipeline runs

### Slack
- [ ] Webhook URL configured in GitHub secrets
- [ ] Messages sending to channel
- [ ] Rich formatting visible
- [ ] Findings count displayed
- [ ] Pipeline links working

## Overall Pipeline

- [ ] All 8 stages execute sequentially
- [ ] No stage hangs or times out
- [ ] Artifacts uploaded and downloadable
- [ ] No security warnings in output
- [ ] Pipeline completes in ~20-30 minutes

## Sign-off

Tested by: [Your Name]
Date: [Date]
Result: ✅ PASS / ❌ FAIL

EOF

cat VERIFICATION-CHECKLIST.md
```

---

## 🧪 Phase 5: Advanced Testing (Optional)

### **5.1 Test with Intentional Vulnerability**

Insert a mock XSS vulnerability to verify ZAP catches it:

```java
// In app/src/main/java/org/springframework/samples/petclinic/web/OwnerController.java

@GetMapping("/test-xss")
public String testXss(@RequestParam String input, Model model) {
    // ❌ Intentional vulnerability - unescaped output
    model.addAttribute("message", input);  // This will be displayed unescaped
    return "test-xss";
}
```

Create template:
```html
<!-- test-xss.html -->
<div th:utext="${message}"></div>  <!-- utext = unescaped (vulnerable) -->
```

**Test**:
1. Push code
2. Pipeline runs
3. ZAP should detect XSS vulnerability
4. Pipeline should FAIL (HIGH finding)
5. DefectDojo should show finding

**Then**:
- Remove intentional vulnerability
- Commit fix
- Pipeline runs again
- Should PASS (XSS fixed)

### **5.2 Test Active Scanning Mode**

Edit pipeline to enable active scanning:

```yaml
# In .github/workflows/pipeline.yml, ZAP step
zap-baseline.py \
  -t http://127.0.0.1:8080 \
  -J zap-report.json \
  -a \  # <-- Enable active scanning
  -m 15  # <-- 15 minute timeout
```

**Results**:
- Scan will be ~3-5x slower
- More findings may be detected (especially injection issues)
- Report more comprehensive

---

## 🐛 Troubleshooting

### **ZAP Step Fails with "Connection Refused"**

```bash
# Check if Spring Boot app container started
docker ps | grep devops-app

# If not running, check Docker logs
docker logs <container-id>

# Manually test connectivity
curl http://127.0.0.1:8080
```

**Fix**: Increase wait time in pipeline:
```yaml
- name: Start Application Container
  run: |
    # Increase from 12 attempts to 20
    for i in {1..20}; do
      if curl -s http://localhost:8080 >/dev/null; then
        echo "App is UP"
        break
      fi
      sleep 5
    done
```

### **DefectDojo Upload Fails**

```bash
# Test API token
curl -H "Authorization: Token <your_api_token>" \
  http://localhost:8000/api/v2/engagements/


# If 401 Unauthorized, regenerate token in DefectDojo UI
```

### **Grafana Shows No Data**

```bash
# Check Prometheus datasource
curl http://localhost:9090/api/v1/targets

# Check Prometheus scraped targets
# Navigate to http://localhost:9090/targets in browser
# Look for "prometheus" and "spring-actuator" targets
```

### **Slack Notification Not Received**

```bash
# Test webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  $SLACK_WEBHOOK_URL

# Check for "Missing token" or "Invalid" errors
```

---

## 📈 Monitoring & Metrics

After successful test run, track these metrics:

| Metric | Target | Where to View |
|--------|--------|---------------|
| Pipeline Duration | <30 min | Grafana Dashboard 1 |
| MTTD (Mean Time to Detect) | Track trend | Grafana Dashboard 3 |
| Finding Count by Tool | Monitor | DefectDojo > Findings |
| Severity Distribution | No CRITICAL blocking | Grafana Dashboard 2 |
| ZAP Coverage | Full app scope | ZAP report |

---

## ✅ Success Criteria

Pipeline is **fully tested** when:

✅ All 8 stages complete successfully
✅ No HIGH/CRITICAL findings (or properly investigated)
✅ ZAP report generated and uploaded
✅ DefectDojo shows findings
✅ Grafana dashboards updated
✅ Slack notification received
✅ Artifacts downloadable
✅ Execution time: 20-30 minutes
✅ FR-11 compliance verified

---

## 📝 Next Steps

After successful test run:
1. Document any findings/issues
2. Create remediation tasks for vulnerabilities
3. Prepare final project report
4. Archive all test reports and artifacts
5. Present to project stakeholders

---

**Ready? Let's go!** 🚀
