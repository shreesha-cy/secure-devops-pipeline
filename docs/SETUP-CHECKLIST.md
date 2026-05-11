# ✅ Grafana Metrics Fix - Quick Setup Checklist

## The Problem (SOLVED ✅)
- ❌ Grafana dashboard: **NO DATA**
- ❌ Prometheus metrics format error: Duplicate HELP lines
- ❌ Missing GitHub secrets configuration
- ✅ DefectDojo working (independent of metrics)

---

## What Was Fixed

| Issue | Fix | File |
|-------|-----|------|
| Duplicate HELP/TYPE lines | Refactored metric collection to store headers once | `scripts/prometheus-metrics.sh` |
| Empty PUSHGATEWAY_URL | Now uses GitHub secrets via environment variables | `scripts/prometheus-metrics.sh` |
| Missing AUTH support | Added `PUSHGATEWAY_AUTH` secret support | `scripts/prometheus-metrics.sh` |
| Hardcoded GRYPE_THRESHOLD | Made configurable via `GRYPE_THRESHOLD` env var | `scripts/grype-check.sh` |
| Workflow not passing secrets | Changed to pass via `env:` block | `.github/workflows/pipeline.yml` |

---

## 🚀 Quick Start (5 minutes)

### Step 1: Configure GitHub Secrets (2 min)

Go to: **GitHub → Repository → Settings → Secrets and variables → Actions**

Create these 2 **CRITICAL** secrets:

```
1. PUSHGATEWAY_URL
   Value: http://localhost:9091
   (or your Prometheus Pushgateway URL)

2. DEFECTDOJO_URL  
   Value: http://localhost:8000
   (or your DefectDojo URL - MUST include http:// or https://)
```

Optional but recommended:

```
3. PUSHGATEWAY_AUTH
   Value: username:password
   (only if your Pushgateway requires authentication)

4. DEFECTDOJO_API_KEY
   Value: [your DefectDojo API token]
```

### Step 2: Verify Configuration (1 min)

Test Pushgateway is accessible:

```bash
curl -X GET http://localhost:9091/api/v1/status
```

Should return: `{"status":"success","data":{}}`

### Step 3: Push Code & Run Pipeline (1 min)

```bash
git add .
git commit -m "fix: prometheus metrics format and github secrets"
git push
```

### Step 4: Check Results (1 min)

1. Go to **GitHub → Actions** tab
2. Find your latest workflow run
3. Expand **"📊 Push Metrics to Prometheus Pushgateway"** step
4. Look for: ✅ **Metrics pushed successfully (HTTP 202)**

---

## 📊 Verify in Grafana (2 minutes after pipeline completes)

### Test Query

1. Open Grafana: `http://localhost:3000`
2. Go to **Explore** (left sidebar)
3. Select **Prometheus** data source
4. Enter query: `pipeline_trivy_vulnerabilities_total`
5. Press Enter → Should see data!

### Expected Output

```
pipeline_trivy_vulnerabilities_total{severity="critical"} = 5
pipeline_trivy_vulnerabilities_total{severity="high"} = 10
pipeline_trivy_vulnerabilities_total{severity="medium"} = 15
pipeline_trivy_vulnerabilities_total{severity="low"} = 20
```

---

## ❌ Common Issues & Fixes

### Issue: "Error: PUSHGATEWAY_URL is required"
**Fix**: 
- Check that `PUSHGATEWAY_URL` secret is set in GitHub
- Verify the secret value is not empty
- Ensure workflow uses `env:` block properly

### Issue: "Push returned HTTP 400"
**Fix**: This should be fixed in the new version. If you still see it:
- Download the latest `prometheus-metrics.sh`
- Check `metrics-debug.txt` in GitHub workflow logs

### Issue: "Push returned HTTP 401"  
**Fix**:
- Your Pushgateway requires authentication
- Set `PUSHGATEWAY_AUTH` secret with format: `username:password`

### Issue: "Metrics appear in Pushgateway but not in Prometheus"
**Fix**:
- Check Prometheus is scraping Pushgateway
- Verify Prometheus config has Pushgateway target
- Check Prometheus logs for scrape errors

### Issue: "Prometheus metrics received but Grafana shows no data"
**Fix**:
- Verify Grafana's Prometheus data source is configured correctly
- Check Grafana logs
- Try querying directly in Prometheus first (Explore tab in Grafana)

---

## 📁 Key Files Changed

```
✅ scripts/prometheus-metrics.sh
   - Fixed duplicate HELP/TYPE lines
   - Added env var support for secrets
   - Enhanced error handling
   - Now validates metrics format

✅ scripts/grype-check.sh
   - Made GRYPE_THRESHOLD configurable

✅ .github/workflows/pipeline.yml
   - Updated to pass secrets via env:

✅ docs/GITHUB-SECRETS-SETUP.md
   - Comprehensive secret configuration guide

✅ docs/GRAFANA-METRICS-FIX.md
   - Detailed explanation of all fixes
```

---

## 📚 Documentation

- **Full Setup Guide**: `docs/GITHUB-SECRETS-SETUP.md`
- **Technical Details**: `docs/GRAFANA-METRICS-FIX.md`
- **Troubleshooting**: `docs/GRAFANA-TROUBLESHOOTING.md`
- **Grafana Import**: `docs/GRAFANA-IMPORT-GUIDE.md`

---

## 🔐 Security Notes

1. **Never** commit secrets to Git
2. **Use** GitHub secrets for sensitive data
3. **Rotate** tokens periodically (Docker Hub, SonarQube, etc.)
4. **Review** workflow logs - secrets are masked but endpoints may be visible

---

## ✨ What Happens Now

**On Each Pipeline Run:**

```
1. Security scans run (Trivy, Checkov, OWASP, etc.)
2. Results are parsed into Prometheus metrics
3. Metrics are formatted correctly (no duplicates!)
4. Metrics are pushed to Prometheus Pushgateway ✅
5. Prometheus scrapes metrics every 30 seconds
6. Grafana displays metrics in real-time 📊
7. DefectDojo receives scan results via API ✅
```

---

## 🎯 Next Steps

After confirming metrics flow to Grafana:

1. ✅ Create custom Grafana dashboards
2. ✅ Set up Prometheus alerts for critical vulnerabilities
3. ✅ Configure Grafana notifications (Slack, Teams, email)
4. ✅ Set up continuous monitoring

---

**Questions?** Check the docs or review workflow logs for detailed error messages.

**Ready?** 👉 Set up those GitHub secrets and push! 🚀
