# 🔧 PIPELINE TROUBLESHOOTING GUIDE

## ❌ **ISSUES IDENTIFIED & FIXED**

### **Issue #1: Pipeline Only Triggered on `main` Branch** ✅ FIXED
**Problem:**
```yaml
on:
  push:
    branches:
      - main  # ❌ Only main branch
```

**Why it matters:**
- Your feature branch commits (`feature/anoop-local-test`) don't trigger the pipeline
- 107 runs but many on the `main` branch

**Fixed:**
```yaml
on:
  push:
    branches:
      - main
      - '**'  # ✅ Now triggers on ALL branches
```

---

### **Issue #2: Wrong Runner Type** ✅ FIXED
**Problem:**
```yaml
runs-on: ubuntu-latest  # ❌ GitHub-hosted, no Docker daemon
```

**Why it matters:**
- GitHub-hosted runners don't have Docker daemon for building/pushing images
- Can't run Docker commands like `docker build`, `docker push`
- Pipeline fails at Docker build step

**Fixed:**
```yaml
runs-on: self-hosted  # ✅ Your local runner with Docker
```

**Verify your self-hosted runner is registered:**
```bash
# On your machine, check if runner is registered
ls -la ~/.github-runner  # or wherever you configured it
```

---

### **Issue #3: Hardcoded Docker Image Name** ✅ FIXED
**Problem:**
```yaml
# Build
run: docker build -t anoop1605/devops-app -f docker/Dockerfile .

# Push
run: docker push anoop1605/devops-app

# Scan
image-ref: anoop1605/devops-app
```

**Why it matters:**
- Only works for `anoop1605` account
- Fails with authentication error when pushing
- Not portable across different accounts

**Fixed:**
```yaml
# Build
run: docker build -t ${{ secrets.DOCKER_USERNAME }}/devops-app -f docker/Dockerfile .

# Push
run: docker push ${{ secrets.DOCKER_USERNAME }}/devops-app

# Scan
image-ref: ${{ secrets.DOCKER_USERNAME }}/devops-app
```

---

### **Issue #4: Unstable SonarQube Service** ✅ FIXED
**Problem:**
```yaml
services:
  sonarqube:
    image: sonarqube:latest  # ❌ Unstable, always latest
```

**Why it matters:**
- `latest` tag changes frequently
- Can have breaking changes
- Service might not start properly in GitHub Actions

**Fixed:**
```yaml
services:
  sonarqube:
    image: sonarqube:9.9-community  # ✅ Stable version
    options: >
      --health-cmd "curl -f http://localhost:9000/api/system/status || exit 1"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

---

## 🔐 **REQUIRED SECRETS CONFIGURATION**

Your pipeline needs these secrets to work. Set them in GitHub:

### **Step 1: Go to Repository Settings**
```
https://github.com/Anoop1605/secure-devops-pipeline/settings/secrets/actions
```

### **Step 2: Add These Secrets** (Click "New repository secret")

| Secret Name | Value | Example |
|------------|-------|---------|
| `DOCKER_USERNAME` | Your Docker Hub username | `anoop1605` |
| `DOCKER_PASSWORD` | Your Docker Hub token/password | `dckr_pat_xxx...` |
| `DEFECTDOJO_URL` | DefectDojo URL | `http://localhost:8000` |
| `DEFECTDOJO_API_KEY` | DefectDojo API key | `a1b2c3d4e5f6...` |
| `DEFECTDOJO_ENGAGEMENT_ID` | Engagement ID | `1` |
| `NVD_API_KEY` | OWASP NVD API key | (optional) |

### **Step 3: Verify Secrets Are Set**
```bash
# You can't see the values, but you can see they exist
# Go to: https://github.com/Anoop1605/secure-devops-pipeline/settings/secrets/actions
# ✅ Should see all secrets listed
```

---

## 🚀 **HOW TO TRIGGER THE PIPELINE NOW**

### **Method 1: Push to ANY Branch** (Recommended for testing)
```bash
# Make a change
echo "# Test" >> README.md

# Commit and push to feature branch
git add README.md
git commit -m "test: trigger pipeline"
git push origin feature/anoop-local-test

# Go to Actions page and watch it run
https://github.com/Anoop1605/secure-devops-pipeline/actions
```

### **Method 2: Manual Trigger** (If supported)
```bash
# Create a .github/workflows/manual-trigger.yml file with:
# on:
#   workflow_dispatch:

# Then you can trigger from GitHub Actions UI
```

### **Method 3: Push to main Branch**
```bash
# Create a PR and merge to main
# This will always trigger the pipeline
git push origin feature/anoop-local-test
# Then open PR and merge to main
```

---

## ✅ **VERIFY PIPELINE IS WORKING**

### **Step 1: Check Trigger Configuration**
```bash
# View the workflow file
cat .github/workflows/pipeline.yml | head -20

# Should show:
# on:
#   push:
#     branches:
#       - main
#       - '**'  # All branches
```

### **Step 2: Check Runner Status**
```bash
# If using self-hosted runner, verify it's online
# Go to: Settings → Actions → Runners
# Should show: ✅ Online
```

### **Step 3: Check Secrets Configured**
```bash
# Verify all required secrets exist
# Go to: Settings → Secrets and variables → Actions
# Should show all secrets listed (values hidden)
```

### **Step 4: Make a Test Commit**
```bash
echo "Pipeline test: $(date)" >> README.md
git add README.md
git commit -m "ci: verify pipeline trigger"
git push origin feature/anoop-local-test
```

### **Step 5: Watch the Pipeline Run**
```
Visit: https://github.com/Anoop1605/secure-devops-pipeline/actions
Filter by branch: feature/anoop-local-test
Should see your workflow running
```

---

## 🔍 **DEBUGGING FAILED RUNS**

### **View Workflow Logs**
```bash
# Click on the failed run
# Click on the job name
# See detailed logs for each step
```

### **Common Failures & Solutions**

| Failure | Cause | Solution |
|---------|-------|----------|
| "No such container: devops-app" | App never started | Check earlier stages for build failure |
| "Failed to login to Docker" | Secrets not set | Add DOCKER_USERNAME/PASSWORD to secrets |
| "SonarQube timeout" | Service didn't start | Increase wait time from 60 to 120 seconds |
| "TruffleHog error: unknown flag" | Old TruffleHog version | Update to latest version |
| "Checkov not found" | Docker not available | Use self-hosted runner with Docker |

---

## 📋 **COMPLETE DEBUGGING CHECKLIST**

- [ ] Workflow file has `- '**'` in branches to trigger on all branches
- [ ] Runner is set to `self-hosted`
- [ ] DOCKER_USERNAME secret is set
- [ ] DOCKER_PASSWORD secret is set
- [ ] Self-hosted runner is online (Settings → Runners)
- [ ] Docker daemon is running on self-hosted machine
- [ ] SonarQube version is pinned to `9.9-community`
- [ ] All service health checks are configured
- [ ] No hardcoded image names (all use `${{ secrets.DOCKER_USERNAME }}`)
- [ ] Latest test commit pushed successfully

---

## 🎯 **EXPECTED BEHAVIOR AFTER FIXES**

**Before (Broken):**
```
❌ Only main branch triggers
❌ Feature branches ignored
❌ Fails on Docker build
❌ Inconsistent runner behavior
```

**After (Fixed):**
```
✅ All branches trigger pipeline
✅ Feature branches work
✅ Docker build/push succeeds
✅ Consistent execution on self-hosted runner
✅ All 8 stages complete successfully
```

---

## 💬 **NEED HELP?**

If pipeline still fails after these fixes, check:

1. **Self-hosted runner status**: 
   - Settings → Actions → Runners
   - Should show ✅ Online (not Offline)

2. **Docker running**:
   ```bash
   docker ps
   docker --version
   ```

3. **Secrets properly set**:
   - Settings → Secrets and variables → Actions
   - All required secrets should be listed

4. **Workflow syntax**:
   ```bash
   # Check for YAML errors
   cat .github/workflows/pipeline.yml | grep -i "error"
   ```

5. **Recent commits**:
   ```bash
   git log --oneline -5
   ```

---

**After these fixes, your pipeline should run smoothly on every commit! 🚀**
