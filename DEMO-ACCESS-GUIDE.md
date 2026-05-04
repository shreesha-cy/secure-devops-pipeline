# 🎬 SDOP-2025 FINAL DEMO - Access Guide & Navigation

**Date**: April 26, 2026
**Status**: ✅ ALL SYSTEMS ONLINE
**Commit**: a5f5d2c (Enhanced Stage 7-8)

---

## 🟢 Live Services Status

| Service | Status | Port | Access URL |
|---------|--------|------|-----------|
| 🔴 DefectDojo Django | ✅ UP (58 sec) | 3031 | Internal |
| 🟠 DefectDojo Nginx | ✅ UP (57 sec) | 8000 | http://localhost:8000 |
| 📊 Grafana | ✅ UP (15 min) | 3000 | http://localhost:3000 |
| 💾 PostgreSQL | ✅ UP (15 min) | 5432 | Internal |
| 🔴 Redis | ✅ UP (15 min) | 6379 | Internal |
| 📈 Prometheus | ✅ UP (15 min) | 9090 | http://localhost:9090 |
| 🐳 Celery Worker | ✅ UP (58 sec) | N/A | Internal |

**Overall Status**: 🟢 **100% OPERATIONAL**

---

## 🌐 DEMO ACCESS LINKS

### **1️⃣ DefectDojo - Vulnerability Management** 
**URL**: http://localhost:8000
**Login**: 
- Username: `admin`
- Password: `admin123`

**What to Show**:
- [ ] Navigate: Engagements → SDOP-2025
- [ ] Show: All findings from all tools
- [ ] Explain: Severity levels (CRITICAL, HIGH, MEDIUM, LOW)
- [ ] Highlight: Scan history and trends
- [ ] Demo: Filter by tool (ZAP, Trivy, SonarQube, etc.)

**Key Stats to Check**:
```
Total Findings: [Check Dashboard]
├── CRITICAL: X
├── HIGH: X
├── MEDIUM: X
└── LOW: X

Latest Scan: [Check timestamp]
Engagement ID: 1 (SDOP-2025)
```

---

### **2️⃣ Grafana - Monitoring & Dashboards**
**URL**: http://localhost:3000
**Login**:
- Username: `admin`
- Password: `admin`

**3 Dashboards Available**:

#### **Dashboard 1: Pipeline Health**
- Pipeline success rate (%)
- Average pipeline duration
- Top failing stages
- 7-day trend

#### **Dashboard 2: Findings Summary**
- Findings by tool (bar chart)
- Severity distribution (pie chart)
- CVSS score histogram
- Trend over time

#### **Dashboard 3: MTTD Tracking**
- Mean Time To Detect metrics
- Stage-level detection times
- Finding detection rate
- Performance trends

**How to Import Dashboards** (if needed):
```bash
1. Go to: http://localhost:3000/dashboard/import
2. Click: "Paste JSON"
3. Copy contents from: grafana-dashboards/01-pipeline-health.json
4. Select Data Source: Prometheus
5. Click: Import
6. Repeat for other 2 dashboards
```

---

### **3️⃣ Prometheus - Metrics Database**
**URL**: http://localhost:9090

**What to Show**:
- [ ] Go to: Status → Targets
- [ ] Show: Which targets are being scraped
- [ ] Explain: Prometheus collects metrics for Grafana

**Current Targets**:
- `prometheus` (self-monitoring)
- `spring-actuator` (if app running)

---

### **4️⃣ GitHub Actions - Pipeline Execution**
**URL**: https://github.com/YOUR_USERNAME/secure-devops-pipeline/actions

**What to Show**:
- [ ] Latest workflow run (a5f5d2c commit)
- [ ] All 8 stages and their status
- [ ] Real-time logs for each stage
- [ ] Pipeline duration and timestamps

**Expected Timeline**:
```
⏱️ ~2-3 min  : Stages 1-2 (Secrets + SAST)
⏱️ ~3-5 min  : Stages 3-4 (SCA + IaC)
⏱️ ~5-10 min : Stages 5-6 (Container + Policy)
⏱️ ~3-5 min  : Stage 7 (ZAP DAST) ← Enhanced!
⏱️ ~1-2 min  : Stage 8 (DefectDojo + Notifications)
═══════════════════════════════
⏱️ ~20-30 min: TOTAL
```

---

## 📋 Demo Walkthrough Script

### **Opening Statement** (30 sec)
```
"Welcome to SDOP-2025, a comprehensive Secure DevOps Pipeline project!

This 8-stage automated security pipeline integrates multiple security 
tools to protect our Spring Boot application from:
- Secret leaks
- Code vulnerabilities
- Dependency vulnerabilities
- Container & infrastructure misconfigurations
- Runtime vulnerabilities
- Policy violations

Everything runs automatically on each code commit through GitHub Actions."
```

### **Stage 1-6 Overview** (1 min)
```
"The first 6 stages run automatically before deployment:

1. Secret Detection (TruffleHog) - Finds leaked credentials
2. SAST with SonarQube - Detects code quality issues
3. SCA (Dependency Check) - Finds vulnerable packages
4. IaC Scanning (Hadolint, Checkov) - Validates Dockerfiles & K8s configs
5. Container Hardening (Trivy, Grype) - Scans Docker images
6. Policy Gate (OPA) - Enforces custom security policies

All findings are uploaded to DefectDojo for central tracking."
```

### **Stage 7: DAST Demonstration** (2 min)
```
"Stage 7 is our DAST (Dynamic Application Security Testing) stage
powered by OWASP ZAP. This is enhanced to:

✅ Run active scanning (not just baseline)
✅ Detect runtime vulnerabilities
✅ Enforce FR-11 compliance: HIGH/CRITICAL findings block the pipeline
✅ Generate JSON report for DefectDojo

[Show GitHub Actions logs for ZAP stage]

The scan runs against the deployed Spring Boot app and checks for:
- Cross-Site Scripting (XSS)
- Cross-Site Request Forgery (CSRF)
- Missing security headers
- SQL Injection vulnerabilities
- Authentication/authorization issues
```

### **Stage 8: Reporting & Integration** (2 min)
```
"Stage 8 consolidates all findings:

1. DefectDojo Integration
   - All scan reports uploaded
   - Findings deduplicated and tracked
   - Severity classification
   
2. Slack Notifications
   - Team alerts with findings summary
   - Pipeline success/failure status
   - Links to DefectDojo and GitHub
   
3. Grafana Dashboards
   - Real-time metrics visualization
   - Pipeline health trends
   - MTTD (Mean Time To Detect) tracking
   - Finding trends over time
   
4. Prometheus Metrics
   - Collects pipeline metrics
   - Stores time-series data
   - Powers Grafana dashboards
```

### **DefectDojo Navigation** (2 min)
```
[Open http://localhost:8000 in browser]

"This is DefectDojo, our centralized vulnerability management platform.

On the left, we have Engagements - these group findings by project.
We created engagement 'SDOP-2025' for this project.

Let's click on SDOP-2025 to see findings from all stages:
- SonarQube findings: Code quality issues
- Trivy findings: Container vulnerabilities
- ZAP findings: Runtime vulnerabilities
- Grype findings: Package vulnerabilities
- Dependency Check: Component vulnerabilities

Each finding shows:
- Severity (CRITICAL, HIGH, MEDIUM, LOW)
- CVSS score
- Description
- Remediation guidance
"
```

### **Grafana Dashboard Tour** (2 min)
```
[Open http://localhost:3000 in browser]

"This is Grafana - our real-time monitoring and visualization platform.

Dashboard 1 - Pipeline Health:
Shows our pipeline's success rate, average duration, and failing stages.
Currently at 100% success rate with 8/8 stages passing.

Dashboard 2 - Findings Summary:
Breaks down findings by severity and tool.
This helps us see which tools find what types of vulnerabilities.

Dashboard 3 - MTTD Tracking:
'Mean Time To Detect' - how quickly we find vulnerabilities.
Ranges from 2-8 minutes depending on the security stage.
"
```

### **Slack Integration** (1 min)
```
"Slack integration keeps the team informed:

Every pipeline run sends a notification with:
- Pipeline status (✅ or ❌)
- Branch and commit info
- DAST findings count (CRITICAL + HIGH)
- Links to GitHub and DefectDojo

Team members can immediately see findings and take action.
"
```

### **Closing Statement** (30 sec)
```
"This SDOP-2025 pipeline demonstrates:

✅ Complete automation of security testing
✅ Multiple security tools working together
✅ Blocking gates on critical vulnerabilities (FR-11)
✅ Centralized findings management (DefectDojo)
✅ Real-time monitoring (Grafana)
✅ Team notifications (Slack)
✅ MTTD metrics tracking

All 8 stages are running successfully, ensuring our application
is continuously scanned for vulnerabilities before and after deployment.

Ready to take questions!"
```

---

## 📊 Demo Checklist

### **Before Starting**
- [ ] All services running (verify with `docker ps`)
- [ ] DefectDojo accessible (http://localhost:8000)
- [ ] Grafana accessible (http://localhost:3000)
- [ ] GitHub Actions page open in browser
- [ ] Latest commit pushed (a5f5d2c)
- [ ] Slack channel prepared (if available)
- [ ] Screen resolution adjusted for demo

### **During Demo**
- [ ] Show GitHub Actions pipeline page
- [ ] Explain 8-stage architecture
- [ ] Demonstrate DefectDojo findings
- [ ] Navigate Grafana dashboards
- [ ] Show ZAP DAST stage in detail
- [ ] Explain FR-11 compliance
- [ ] Show Slack notifications (if available)
- [ ] Answer questions

### **Key Points to Emphasize**
1. ✅ **Fully Automated** - No manual intervention required
2. ✅ **Blocking Gates** - HIGH/CRITICAL findings stop deployment
3. ✅ **Centralized** - All findings in one place (DefectDojo)
4. ✅ **Monitored** - Real-time dashboards (Grafana)
5. ✅ **Integrated** - Team notifications (Slack)
6. ✅ **Traceable** - MTTD metrics and trends
7. ✅ **Scalable** - Can add more tools/stages as needed
8. ✅ **Documented** - Comprehensive guides in `/docs`

---

## 🎁 Demo Artifacts & Downloads

### **From GitHub Actions**
1. Go to: https://github.com/YOUR_USERNAME/secure-devops-pipeline/actions
2. Click latest run (a5f5d2c)
3. Scroll down to "Artifacts"
4. Download: `sdop-security-reports`

**Contains**:
```
sdop-security-reports/
├── gitleaks-report.json (Secrets scanning results)
├── trivy-report.json (Container image scan)
├── app/target/dependency-check-report.xml (SCA results)
└── zap-report.json (DAST results)
```

### **Documentation**
Located in `/docs`:
- `FINAL-DEMO-GUIDE.md` - This guide
- `ZAP-ENHANCEMENT-GUIDE.md` - DAST stage details
- `PIPELINE-TESTING-GUIDE.md` - Testing procedures
- `DEFECTDOJO-SETUP.md` - DefectDojo configuration
- `GRAFANA-IMPORT-GUIDE.md` - Dashboard setup

---

## 🔧 Troubleshooting During Demo

### **If DefectDojo is slow**
```
Restart: docker-compose -f docker/monitoring/docker-compose.yml restart defectdojo
Wait: ~30 seconds for it to come back online
```

### **If Grafana shows no data**
```
1. Check Prometheus: http://localhost:9090/targets
2. Ensure "prometheus" target is "UP"
3. Restart Grafana: docker-compose -f docker/monitoring/docker-compose.yml restart grafana
```

### **If pipeline isn't showing**
```
1. Verify commit was pushed: git push origin feature/anoop-feature
2. Check GitHub: https://github.com/YOUR_USERNAME/secure-devops-pipeline/actions
3. Trigger new run if needed
```

---

## ⏱️ Estimated Demo Duration

| Section | Time |
|---------|------|
| Intro & Architecture | 2 min |
| Stages 1-6 Overview | 1 min |
| Stage 7 (DAST) Details | 2 min |
| Stage 8 (Reporting) Details | 2 min |
| DefectDojo Demo | 2 min |
| Grafana Dashboards | 2 min |
| Slack Integration | 1 min |
| Q&A | 3 min |
| **Total** | **~15 min** |

---

## 📞 Quick Reference

**Your Role**: Anoop S (1MS23CY006)
**Responsibilities**: DAST (Stage 7) + Reporting (Stage 8)
**Key Enhancements**: 
- Active ZAP scanning
- FR-11 compliance enforcement
- Enhanced Slack notifications
- MTTD tracking

**Contact if Questions**:
- Team: Shreesha, Ananya C, Mohit Patil
- Supervisor: M.S. Ramaiah Institute VI Semester

---

## 🚀 Next Steps After Demo

1. ✅ Present demo to instructors/stakeholders
2. ✅ Collect feedback
3. ✅ Address any questions
4. ✅ Create final project report
5. ✅ Archive all artifacts and documentation
6. ✅ Prepare presentation slides

**Status**: Ready for Demo & Evaluation! 🎉

---

