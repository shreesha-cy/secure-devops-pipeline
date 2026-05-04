# OWASP ZAP Enhancement Guide for SDOP-2025 (Stage 7 - DAST)

**Role**: Anoop S (1MS23CY006) - DAST Stage Lead

---

## 📋 Overview

This guide explains the **enhanced OWASP ZAP configuration** for Stage 7 (Dynamic Application Security Testing) of the SDOP-2025 pipeline.

### What Changed from Baseline to Enhanced?

| Aspect | Baseline | Enhanced |
|--------|----------|----------|
| Scan Type | Passive only | Active + Baseline |
| Fail Condition | Any alert blocks | HIGH/CRITICAL block (FR-11) |
| Context Support | None | Full context file support |
| Report Parsing | Simple exit code | JSON parsing for severity analysis |
| Slack Alerts | Generic message | Rich findings summary |

---

## 🎯 Requirements (From PRD)

**Functional Requirement FR-11**:
> Stage 7 - Any OWASP ZAP alert rated HIGH or CRITICAL MUST fail the pipeline

**Key Metrics**:
- ✅ Non-intrusive (baseline) by default
- ✅ Option to enable active scanning
- ✅ Proper severity thresholds
- ✅ JSON report generation
- ✅ MTTD tracking

---

## 🔧 Files Created

### 1. **zap/sdop-context.xml**
ZAP context configuration defining:
- Target scope: `http://127.0.0.1:8080.*`
- Technologies: Java 17, Spring Boot 3.x
- Exclude patterns: Static resources, actuator endpoints
- Session management: Cookie-based

**Purpose**: Tells ZAP exactly what to scan and what to ignore.

### 2. **zap/zap-active-scan.py**
Python script for advanced ZAP scanning (future enhancement).

**Features**:
- Supports both baseline and active scanning
- Parses JSON report
- Enforces FR-11 (HIGH/CRITICAL block)
- Detailed findings summary

### 3. **.github/workflows/pipeline.yml** (Updated)
Enhanced pipeline stage with:
- Active scanning flag (`-a`)
- JSON report parsing
- FR-11 compliance check
- Detailed failure messages

---

## 🚀 How It Works

### **Pipeline Execution Flow (Stage 7)**

```
1. START APPLICATION
   └─> docker run -d -p 8080:8080 shreesha369/devops-app
   └─> Wait until http://localhost:8080 responds (UP)

2. RUN ZAP SCAN
   └─> docker run zaproxy zap-baseline.py \
       -t http://127.0.0.1:8080 \
       -J zap-report.json \
       -a (active scanning flag)

3. PARSE RESULTS (FR-11 Check)
   └─> Read zap-report.json
   └─> Count CRITICAL (riskcode=3) findings
   └─> Count HIGH (riskcode=2) findings
   
4. DECISION
   ├─ If CRITICAL + HIGH > 0:
   │  └─> FAIL ❌ (exit 1)
   │  └─> Block pipeline
   │  └─> Send alert to Slack
   │
   └─ If CRITICAL + HIGH == 0:
      └─> PASS ✅ (exit 0)
      └─> Continue to next stage

5. UPLOAD REPORT
   └─> Send zap-report.json to DefectDojo
   └─> DefectDojo imports findings
```

---

## 📊 Scan Types Explained

### **Baseline Scan (Current)**
- ✅ **Fast** (~2-5 minutes)
- ✅ **Safe** - Passive, non-intrusive
- ✅ Detects: Common vulnerabilities (XSS, CSRF, missing headers)
- ❌ Misses: Logic flaws, authentication bypasses

**When to Use**: CI/CD pipeline, frequent runs

### **Active Scan (Optional)**
- ⚠️ **Slow** (~10-20 minutes per endpoint)
- ⚠️ **Intrusive** - Sends payloads, may trigger WAF
- ✅ Detects: SQL injection, command injection, XXE, XXE
- ✅ Better coverage than baseline

**When to Use**: Pre-release testing, security reviews

---

## 🎯 Risk Codes Explained

| Code | Severity | Color | Action |
|------|----------|-------|--------|
| 3 | CRITICAL | 🔴 | **BLOCK** (FR-11) |
| 2 | HIGH | 🟠 | **BLOCK** (FR-11) |
| 1 | MEDIUM | 🟡 | Warn (log only) |
| 0 | LOW | 🟢 | Inform (log only) |

**FR-11 Rule**: If Code 3 OR Code 2 detected → Pipeline **FAILS** ❌

---

## 📋 ZAP Report Format

ZAP generates JSON with this structure:

```json
{
  "site": [
    {
      "name": "http://127.0.0.1:8080",
      "alerts": [
        {
          "pluginid": "10015",
          "pluginname": "Re-examine Cache-control Directives",
          "title": "Re-examine Cache-control Directives",
          "riskcode": "1",  // 0=Low, 1=Medium, 2=High, 3=Critical
          "confidence": "1", // 1=Low, 2=Medium, 3=High
          "riskdesc": "Medium",
          "confidencedesc": "Low",
          "description": "...",
          "instances": [
            {
              "uri": "http://127.0.0.1:8080/",
              "method": "GET",
              "evidence": "..."
            }
          ]
        }
      ]
    }
  ]
}
```

---

## 🔍 Interpreting Results

### Example 1: PASS ✅
```
📊 ZAP Findings:
   🔴 CRITICAL: 0
   🟠 HIGH:     0

✅ FR-11 COMPLIANT: No HIGH/CRITICAL findings
```
→ Pipeline **continues** to next stage

### Example 2: FAIL ❌
```
📊 ZAP Findings:
   🔴 CRITICAL: 1
   🟠 HIGH:     2

❌ FR-11 VIOLATION: Found 3 HIGH/CRITICAL findings - BLOCKING PIPELINE
```
→ Pipeline **stops** (DefectDojo upload still happens)
→ Slack alert sent with findings summary

---

## 🛠️ Customization Options

### **Option 1: Enable Active Scanning**
Edit `.github/workflows/pipeline.yml`, ZAP scan step:

```bash
# Current (baseline only):
zap-baseline.py -t http://127.0.0.1:8080 -J zap-report.json

# Active scanning (add -a flag):
zap-baseline.py -t http://127.0.0.1:8080 -J zap-report.json -a

# Time limit for active scan (default: 60 min):
zap-baseline.py -t http://127.0.0.1:8080 -J zap-report.json -a -m 20
# (20 = 20 minutes max)
```

### **Option 2: Use Context File**
```bash
# With context (future enhancement):
zap-baseline.py -t http://127.0.0.1:8080 \
  -J zap-report.json \
  -U <username> \
  -P <password>
```

### **Option 3: Adjust Fail Threshold**
Currently: Block on HIGH or CRITICAL
To block only on CRITICAL, edit pipeline:

```bash
# Change this line:
BLOCKING_FINDINGS=$((CRITICAL + HIGH))

# To:
BLOCKING_FINDINGS=$((CRITICAL))  # Only CRITICAL blocks
```

---

## 📝 Common ZAP Findings & Fixes

### **1. Missing Security Headers**
**Finding**: Cache-control, X-Frame-Options, X-Content-Type-Options
**Fix**: Add to Spring Boot `WebSecurityConfig`:
```java
.headers()
  .contentSecurityPolicy("default-src 'self'")
  .xssProtection()
  .frameOptions().deny();
```

### **2. Cross-Site Request Forgery (CSRF)**
**Finding**: CSRF tokens not properly validated
**Fix**: Spring Boot CSRF protection (enabled by default):
```java
.csrf().csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
```

### **3. Cross-Site Scripting (XSS)**
**Finding**: User input reflected without encoding
**Fix**: Use Thymeleaf (escapes by default):
```html
<!-- Safe: Thymeleaf escapes -->
<p th:text="${userInput}"></p>

<!-- Unsafe: Raw HTML -->
<p th:utext="${userInput}"></p>
```

### **4. SQL Injection**
**Finding**: Unsanitized database queries
**Fix**: Use parameterized queries (JPA/Hibernate):
```java
// ✅ Safe
repository.findByUsername(username);

// ❌ Unsafe
em.createQuery("SELECT u FROM User u WHERE username='" + username + "'")
```

---

## 🧪 Testing Your Changes

### **Local Test**
```bash
# 1. Start Spring Boot app
cd app
mvn spring-boot:run

# 2. Run ZAP baseline locally
docker run --rm -v $PWD:/zap/wrk/:rw \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:8080 -J /zap/wrk/zap-report.json

# 3. View report
cat zap-report.json | jq '.'
```

### **Pipeline Test**
```bash
# Commit and push changes
git add .github/workflows/pipeline.yml
git commit -m "enhance: ZAP active scanning with FR-11 compliance"
git push

# GitHub Actions will run the enhanced pipeline automatically
# View results in Actions tab
```

---

## 📊 Metrics for DefectDojo

After each pipeline run, DefectDojo will show:
- **Scan Type**: "ZAP Scan"
- **Findings Count**: By severity (CRITICAL, HIGH, MEDIUM, LOW)
- **CVSS Scores**: Risk ratings for each finding
- **Remediation Guidance**: ZAP provides suggestions
- **Trend**: Track if findings increase/decrease over time

---

## ✅ Verification Checklist

- [ ] ZAP scan completes in <10 minutes (baseline) or <20 minutes (active)
- [ ] JSON report generated: `zap-report.json`
- [ ] FR-11 compliance enforced (HIGH/CRITICAL blocks)
- [ ] Slack notification includes findings count
- [ ] DefectDojo receives and imports ZAP report
- [ ] No false positives (baseline should have minimal findings on clean code)
- [ ] Real vulnerabilities are caught (XSS, CSRF, etc.)

---

## 🐛 Troubleshooting

### **ZAP: Connection Refused**
**Error**: `Failed to connect to 127.0.0.1:8080`
**Cause**: Spring Boot app not running
**Fix**: Verify app started in previous step, check Docker network

### **ZAP: Timeout**
**Error**: `Scan timeout after 600s`
**Cause**: App hanging or ZAP stuck
**Fix**: Increase timeout in pipeline, or check app logs

### **Report Not Found**
**Error**: `zap-report.json: No such file or directory`
**Cause**: ZAP crashed or report not generated
**Fix**: Check ZAP logs, verify app is accessible

### **DefectDojo Upload Fails**
**Error**: `401 Unauthorized`
**Cause**: Invalid API token
**Fix**: Regenerate API token in DefectDojo, update GitHub secrets

---

## 📖 References

- **ZAP Baseline Script**: https://www.zaproxy.org/docs/docker/baseline-scan/
- **ZAP Active Scan**: https://www.zaproxy.org/docs/docker/full-scan/
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **FR-11 Requirement**: See PRD Section 8.2, Functional Requirements

---

## 🚀 Next Steps

1. ✅ Enhanced ZAP configuration deployed
2. ⏭️ Test full pipeline end-to-end (next section)
3. ⏭️ Monitor DefectDojo for findings
4. ⏭️ Create final security report

