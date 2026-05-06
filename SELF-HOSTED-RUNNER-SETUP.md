# 🔧 Self-Hosted Runner Setup for DefectDojo Integration

> **Last Updated**: May 2026  
> **Purpose**: Enable GitHub Actions to access localhost:8000 (DefectDojo) on your Windows machine

---

## 🎯 Quick Decision Tree

```
Do you want GitHub Actions to access localhost:8000 (DefectDojo)?
│
├─ YES → Follow "Self-Hosted Runner Setup" below
│
└─ NO  → Keep using ubuntu-latest with Host LAN IP in DEFECTDOJO_URL
         Example: http://192.168.1.50:8000
```

---

## 📊 Runner Types Comparison

| Aspect | GitHub-Hosted (`ubuntu-latest`) | Self-Hosted (`self-hosted`) |
|--------|---|---|
| **Access to localhost** | ❌ NO | ✅ YES |
| **Access to DefectDojo on :8000** | ❌ NO (unless uses Docker bridge IP or LAN IP) | ✅ YES |
| **Maintenance** | Automatic | Manual (you manage the agent) |
| **Cost** | Minutes counted | Free |
| **Suitable for SDOP-2025** | ❌ Not ideal for local DefectDojo | ✅ Recommended |

---

## ✅ OPTION 1: Self-Hosted Runner (Recommended)

### **Step 1: Download GitHub Actions Runner**

1. Go to your GitHub repo
2. Navigate: **Settings** → **Actions** → **Runners** → **New self-hosted runner**
3. Select **Windows** as the operating system
4. Download the runner package

### **Step 2: Configure on Your Windows Machine**

```powershell
# Open PowerShell as Administrator
# Create a directory for the runner
mkdir C:\github-runner
cd C:\github-runner

# Extract the downloaded runner
# (Follow GitHub's instructions for your OS)

# Configure the runner
.\config.cmd --url https://github.com/Anoop1605/secure-devops-pipeline `
             --token <TOKEN_FROM_GITHUB>
```

### **Step 3: Run the Runner Agent**

```powershell
# Keep this running in the background (new PowerShell window)
# Terminal 1: Runner
.\run.cmd

# Terminal 2: Your normal work continues...
```

**Expected Output:**
```
√ Connected to GitHub
√ Waiting for jobs...
```

### **Step 4: Update pipeline.yml**

```yaml
jobs:
  build:
    runs-on: self-hosted  # ✅ Changed from ubuntu-latest
```

### **Step 5: Verify in GitHub**

Go to: **Settings** → **Actions** → **Runners**  
You should see your runner listed as **Idle** (waiting for jobs)

---

## 🔒 Configure GitHub Secrets

### **Required Secrets** (Go to Repo Settings → Secrets and Variables → Actions)

| Secret Name | Value | Example |
|---|---|---|
| `DEFECTDOJO_URL` | URL with protocol prefix | `http://localhost:8000` |
| `DEFECTDOJO_API_KEY` | Your DefectDojo token | From DefectDojo → Admin → API Tokens |
| `DOCKER_USERNAME` | Your Docker Hub username | `anoop1605` |
| `DOCKER_PASSWORD` | Your Docker Hub token | `dckr_pat_xxx...` |
| `NVD_API_KEY` | NVD API key for Dependency Check | (optional) |

### ⚠️ **Critical: Protocol Prefix**

✅ **CORRECT:**
```
DEFECTDOJO_URL = http://localhost:8000
```

❌ **WRONG:**
```
DEFECTDOJO_URL = localhost:8000
```

---

## ⚠️ OPTION 2: GitHub-Hosted Runner with LAN IP (Alternative)

If you prefer to keep `ubuntu-latest`, you must use your **host machine's LAN IP**:

### **How to Find Your LAN IP** (Windows)

```powershell
# Open PowerShell
ipconfig /all

# Look for: IPv4 Address (e.g., 192.168.1.50)
```

### **Set GitHub Secret**

```
DEFECTDOJO_URL = http://192.168.1.50:8000
```

### **Limitations**

- ❌ Only works on the same network
- ❌ Port 8000 must be accessible from GitHub's servers
- ❌ More complex firewall setup required

---

## 🔍 Verification Checklist

### **Before Running Pipeline**

- [ ] Self-hosted runner is running (`.\run.cmd` is active)
- [ ] Runner shows as **Idle** in GitHub Settings → Runners
- [ ] DefectDojo is running: `http://localhost:8000` (accessible in browser)
- [ ] `DEFECTDOJO_URL` secret is set to `http://localhost:8000`
- [ ] `DEFECTDOJO_API_KEY` secret is set with valid token
- [ ] `pipeline.yml` has `runs-on: self-hosted`

### **Test Connection from Windows PowerShell**

```powershell
# Before running pipeline, test connectivity
curl -I http://localhost:8000

# Expected output:
# HTTP/1.1 302 Found
# (or 200 OK if logged out)
```

---

## 🐛 Troubleshooting

### **Problem: `curl: (7) Failed to connect to localhost port 8000`**

**Causes & Solutions:**
1. ✅ DefectDojo not running
   ```bash
   cd docker/monitoring
   docker-compose ps
   docker-compose up -d
   ```

2. ✅ Wrong URL in secret
   - Go to: **Settings → Secrets**
   - Verify `DEFECTDOJO_URL` includes `http://`
   - Check for trailing slashes: `http://localhost:8000` (not `http://localhost:8000/`)

3. ✅ Runner not picked up the change
   - Restart runner: Stop and run `.\run.cmd` again
   - GitHub caches secrets, might take 1-2 minutes

### **Problem: Runner shows `Offline` in GitHub**

- [ ] The `.\run.cmd` process stopped
- [ ] Restart: `.\run.cmd`
- [ ] Check runner logs: Look for error messages in PowerShell output

### **Problem: `Authorization: Token invalid`**

- [ ] Wrong API key in `DEFECTDOJO_API_KEY`
- [ ] Go to DefectDojo → Admin → API Tokens
- [ ] Generate a new token or use existing one
- [ ] Update GitHub secret

### **Problem: `Service Unavailable` from GitHub Actions**

- [ ] DefectDojo container crashed
  ```bash
  docker-compose logs defectdojo
  docker-compose restart defectdojo
  ```

---

## 📝 Current Project Configuration

### **Before Changes**
```yaml
runs-on: ubuntu-latest  # ❌ Cannot access localhost:8000
secrets.DEFECTDOJO_URL: ? (might be incorrectly formatted)
```

### **After Changes**
```yaml
runs-on: self-hosted    # ✅ Can access localhost:8000
secrets.DEFECTDOJO_URL: http://localhost:8000  # ✅ With protocol
```

---

## 🚀 Running Your First Pipeline

1. **Ensure self-hosted runner is active:**
   ```powershell
   # Terminal with runner
   cd C:\github-runner
   .\run.cmd
   # Should show: "Waiting for jobs..."
   ```

2. **Make a commit and push to main:**
   ```bash
   git add .
   git commit -m "Enable self-hosted runner for DefectDojo"
   git push origin main
   ```

3. **Monitor in GitHub:**
   - Go to: **Actions** → Latest workflow run
   - Should show: `self-hosted` runner processing
   - DefectDojo upload step should succeed

---

## 📚 References

- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [DefectDojo API Documentation](https://defectdojo.github.io/django-DefectDojo/integrations/defectdojo_api_v2/)
- [Docker Networking](https://docs.docker.com/network/)

---

## 💡 Tips & Best Practices

1. **Keep runner updated:** Periodically update the GitHub Actions runner
2. **Monitor runner logs:** Check PowerShell output for errors
3. **Use meaningful engagement names:** Pipeline run IDs are good: `Scan - ${{ github.run_id }}`
4. **Test manually first:**
   ```bash
   ./scripts/defectdojo-upload.sh \
     --url http://localhost:8000 \
     --api-key <your-token> \
     --product "Test" \
     --engagement "Manual Test"
   ```

---

**Questions?** Check DEFECTDOJO-SETUP.md or PIPELINE-TROUBLESHOOTING.md
