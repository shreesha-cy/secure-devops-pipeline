# 🚀 Secure DevOps Pipeline – P1 (CI + Docker)

## 👩‍💻 Overview

This repository contains the **P1 (Pipeline Setup)** of the Secure DevOps project.

The pipeline automatically:

* Builds the Spring Boot application
* Creates a Docker image
* Pushes the image to Docker Hub

---

## 🧱 Project Structure

```
secure-devops-pipeline/
│
├── app/                     # Spring Boot application
├── docker/                  # Dockerfile
├── k8s/                     # Kubernetes configs (for later stages)
├── docs/                    # Documentation
└── .github/workflows/       # CI/CD pipeline
```

---

## ⚙️ CI/CD Pipeline (GitHub Actions)

Pipeline triggers on:

```
push → main branch
```

### Steps:

1. Checkout code
2. Setup Java 17
3. Build JAR using Maven
4. Build Docker image
5. Push image to Docker Hub

---

## 🐳 Docker Image Details

**Image:**

```
shreesha369/devops-app:latest
```

**Port:**

```
8080
```

---

## ▶️ How to Run the Application

### Pull image:

```
docker pull shreesha369/devops-app:latest
```

### Run container:

```
docker run -p 8080:8080 shreesha369/devops-app
```

### Open in browser:

```
http://localhost:8080
```

---

## 👥 Team Collaboration Guide

### 🔴 IMPORTANT RULES

* ❌ Do NOT push directly to `main`
* ✅ Always create a new branch
* ✅ Raise a Pull Request (PR)
* ✅ Ensure pipeline passes before merging

---

### 🌿 Branch Workflow

```
git clone <repo-url>
cd secure-devops-pipeline

git checkout -b feature-yourtask
```

After changes:

```
git add .
git commit -m "your message"
git push origin feature-yourtask
```

Then:
👉 Create Pull Request on GitHub

---

## 🔐 For Security Team (P2, P3, P4)

Use this Docker image for scanning/testing:

```
shreesha369/devops-app:latest
```

You can:

* Scan image for vulnerabilities
* Test container security
* Use in Kubernetes deployment

---

## 🧠 Notes

* Application runs on port **8080**
* Built using **Spring Boot 3.x**
* Java version: **17**
* Docker base image: **Eclipse Temurin 17**

---

## ✅ Status

✔ CI Pipeline: Working
✔ Docker Build: Working
✔ Docker Push: Working
✔ Image Verified: Working

---

## 📌 Maintainer (P1)

* Responsible for CI/CD pipeline
* Ensures build + Docker integration works
* Reviews pull requests before merge
