# GitHub Secrets Configuration Guide

This document explains all GitHub secrets required for the Secure DevOps Pipeline and how to set them up.

## Overview

GitHub secrets are encrypted environment variables that are securely passed to your workflow. They are used to store sensitive information like API keys, URLs, and credentials.

## Required Secrets

### 1. **PUSHGATEWAY_URL** ⚠️ CRITICAL
**Purpose**: URL endpoint for Prometheus Pushgateway where metrics are pushed  
**Format**: `http://prometheus-pushgateway:9091` or `https://pushgateway.example.com`  
**Example Value**: `http://127.0.0.1:9091`  
**Required**: YES  
**Impact**: Without this, Grafana dashboard will show **NO DATA**

**Setup**:
```
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: PUSHGATEWAY_URL
4. Value: http://your-pushgateway-url:port
5. Click "Add secret"
```

### 2. **PUSHGATEWAY_AUTH** (Optional)
**Purpose**: Basic authentication credentials for Prometheus Pushgateway (if required)  
**Format**: `username:password`  
**Example**: `admin:secretpassword`  
**Required**: Only if your Pushgateway requires authentication  
**When Used**: If your Pushgateway is protected with HTTP Basic Auth

**Setup**:
```
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: PUSHGATEWAY_AUTH
4. Value: username:password
5. Click "Add secret"
```

### 3. **DEFECTDOJO_URL**
**Purpose**: DefectDojo server URL for uploading security scan results  
**Format**: Include protocol (`http://` or `https://`)  
**Example Value**: `http://localhost:8000` (for self-hosted runner) or `https://defectdojo.example.com`  
**Required**: YES (if DefectDojo step is enabled)  
**Impact**: Security findings won't be uploaded to DefectDojo

**Setup**:
```
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: DEFECTDOJO_URL
4. Value: http://your-defectdojo-url (with protocol!)
5. Click "Add secret"
```

### 4. **DEFECTDOJO_API_KEY**
**Purpose**: API authentication key for DefectDojo  
**How to Generate**:
1. Log in to DefectDojo as admin
2. Click user icon → API v2 Key
3. Click "Generate Key" if not present
4. Copy the API key value

**Setup**:
```
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: DEFECTDOJO_API_KEY
4. Value: [paste the API key from DefectDojo]
5. Click "Add secret"
```

### 5. **DOCKER_USERNAME**
**Purpose**: Docker Hub username for pushing container images  
**Required**: YES  
**Impact**: Docker images cannot be pushed to registry

**Setup**:
```
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: DOCKER_USERNAME
4. Value: your-docker-hub-username
5. Click "Add secret"
```

### 6. **DOCKER_PASSWORD**
**Purpose**: Docker Hub authentication token (not your password!)  
**How to Generate**:
1. Log in to Docker Hub
2. Go to Account Settings → Security → Access Tokens
3. Click "Generate New Token"
4. Give it a name (e.g., "GitHub Actions")
5. Select Read, Write, Delete permissions
6. Copy the token

**Security Note**: Use an Access Token, NOT your Docker password

**Setup**:
```
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: DOCKER_PASSWORD
4. Value: [paste the Docker Hub access token]
5. Click "Add secret"
```

### 7. **SONAR_TOKEN** (Optional)
**Purpose**: SonarQube authentication token for code quality analysis  
**How to Generate**:
1. Log in to SonarQube
2. Click user icon → My Account → Security → Tokens
3. Click "Generate Tokens"
4. Give it a name and generate

**Setup**:
```
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: SONAR_TOKEN
4. Value: [paste SonarQube token]
5. Click "Add secret"
```

### 8. **NVD_API_KEY** (Optional)
**Purpose**: OWASP Dependency Check uses NVD (National Vulnerability Database) API for faster scans  
**How to Get**:
1. Visit https://nvd.nist.gov/developers/request-an-api-key
2. Request an API key (free tier available)

**Setup**:
```
1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: NVD_API_KEY
4. Value: [paste NVD API key]
5. Click "Add secret"
```

## Troubleshooting

### Issue: "Metrics pushed successfully" but Grafana shows no data
**Possible Causes**:
1. `PUSHGATEWAY_URL` is not set or is incorrect
2. `PUSHGATEWAY_URL` has incorrect format (missing `http://` or `https://`)
3. Prometheus is not configured to scrape from Pushgateway
4. Firewall blocking connection to Pushgateway

**Solution**:
```bash
# Test from your machine:
curl -X GET http://your-pushgateway-url:9091/api/v1/metrics/job/secure_devops_pipeline

# Should return metrics data if working correctly
```

### Issue: "Push returned HTTP 400"
**Cause**: Invalid Prometheus metrics format (duplicate HELP lines)  
**Solution**: This should be fixed in the latest version. Check that you have the newest `prometheus-metrics.sh`

### Issue: "Push returned HTTP 401"
**Cause**: Authentication required but `PUSHGATEWAY_AUTH` not provided  
**Solution**: Set `PUSHGATEWAY_AUTH` secret with `username:password` format

### Issue: DefectDojo findings not appearing
**Possible Causes**:
1. `DEFECTDOJO_URL` missing or incorrect
2. `DEFECTDOJO_API_KEY` invalid or expired
3. Product/Engagement doesn't exist in DefectDojo

**Solution**:
```bash
# Test API connection:
curl -H "Authorization: Token YOUR_API_KEY" \
  https://your-defectdojo-url/api/v2/products/

# Should return a list of products
```

## Environment Variables

Some scripts support additional environment variables:

### Grype Check
- `GRYPE_THRESHOLD`: CVSS score threshold (default: 7.0)
  ```yaml
  env:
    GRYPE_THRESHOLD: "7.5"
  ```

## How to Update Secrets

1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Find the secret you want to update
3. Click the pencil icon
4. Update the value
5. Click "Update secret"

## Security Best Practices

1. **Never** commit secrets to the repository
2. **Use separate secrets** for different environments (dev/staging/prod)
3. **Rotate tokens regularly** (especially Docker Hub and SonarQube tokens)
4. **Use the principle of least privilege** - give tokens only the permissions they need
5. **Keep `PUSHGATEWAY_AUTH` secure** - if exposed, an attacker could push fake metrics
6. **Review secret usage** periodically in your workflow logs

## Secret Scope

All secrets defined in repository settings are:
- ✅ Available to all workflows in that repository
- ✅ Available to pull requests from branches (not from forks for security)
- ❌ Visible to fork maintainers in workflow logs
- ❌ Visible in plaintext in workflow files

---

**Need Help?**
- GitHub Secrets Documentation: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions
- Prometheus Pushgateway: https://github.com/prometheus/pushgateway
- DefectDojo API: https://defectdojo.readthedocs.io/en/latest/api_v2.html
