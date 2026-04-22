# 📋 Complete Project Details & History

**Enterprise DevOps & Microservices Task Manager** — CA2 (Continuous Assessment 2)

---

## 🎯 PROJECT OVERVIEW

**Purpose:** Build an enterprise-grade task management application demonstrating:
- Microservices Architecture
- Fully Automated CI/CD Pipeline
- Infrastructure as Code (Terraform)
- Kubernetes Orchestration
- DevSecOps & Security Scanning
- Zero-Downtime Deployments
- Auto-scaling capabilities

---

## 🏗️ ARCHITECTURE & COMPONENTS

### Microservices (Node.js/Express)

#### 1. User-Service (Port 3000)
- Handles user registration and authentication
- Manages user data in MongoDB
- Exposes REST API for user validation
- **Dependencies:** Express, Mongoose, Morgan, CORS

#### 2. Task-Service (Port 3001)
- Handles CRUD operations for tasks
- **Key Feature:** Validates user existence by making HTTP requests to user-service before creating tasks
- Demonstrates true inter-service communication
- **Dependencies:** Express, Mongoose, Morgan, CORS, Axios

#### 3. MongoDB (Port 27017)
- Centralized NoSQL database
- Two collections: `users` and `tasks`
- Persistent storage via PersistentVolumeClaim

#### 4. Frontend
- Pure HTML, CSS, and Vanilla JavaScript SPA
- Session persistence using browser `localStorage`
- Strict data isolation (users only see their own tasks)
- Located in `frontend/index.html`

---

## 🔄 CI/CD PIPELINE (GitHub Actions) - 45 Marks Core

**Fully automated on every `git push` to `main` branch with ZERO manual intervention**

| Stage | Purpose | Tools |
|-------|---------|-------|
| **1. Build & Test** | Install dependencies, run tests, npm audit | Node.js, npm |
| **2. Code Quality** | Static analysis enforcement | SonarCloud |
| **3. Docker Build** | Create container images (Alpine-based) | Docker |
| **4. DevSecOps Scan** | Vulnerability scanning (blocks on CRITICAL/HIGH) | Trivy |
| **5. Image Push** | Upload to Docker Hub | Docker Hub |
| **6. Infrastructure Deploy** | Provision Kubernetes cluster dynamically | Terraform + KinD |
| **7. Verification** | Confirm all deployments successful | kubectl rollout status |

**Matrix Strategy:** Both services tested concurrently for efficiency

---

## ☸️ KUBERNETES DEPLOYMENT

### Infrastructure as Code (Terraform)

All infrastructure is declaratively managed in `terraform/main.tf`:
- Namespace creation
- Deployments (user-service, task-service, mongodb)
- Services (ClusterIP for internal, NodePort/LoadBalancer for external)
- PersistentVolumeClaims for data persistence
- Horizontal Pod Autoscaler (HPA)
- Network Policies for security
- CronJobs for automated backups

**Key Terraform Commands:**
```bash
terraform init              # Initialize
terraform plan              # Preview changes
terraform apply             # Deploy infrastructure
terraform destroy           # Tear down
```

### Deployment Strategy: Rolling Updates
- `maxUnavailable: 1` + `maxSurge: 1`
- **Ensures:** Zero-downtime deployments
- **Benefit:** Kubernetes replaces pods one-at-a-time

### Rollback Strategy
- Kubernetes maintains previous ReplicaSets
- Instant rollback via `kubectl rollout undo`

---

## 🚀 ADVANCED DEVOPS FEATURES (Extra Features - 10 Marks)

### 1. Horizontal Pod Autoscaling (HPA)
- Monitors CPU usage of task-service
- Threshold: 70% CPU utilization
- Scales from 2 → 5 replicas under load
- Scales back down when traffic subsides
- Tested with `load-test.js` (k6 script generating 300+ virtual users)

### 2. Security Vulnerability Scanning
- **Trivy:** Scans Docker images for CVEs
- Blocks deployment if CRITICAL/HIGH vulnerabilities found
- **npm audit:** Detects vulnerable dependencies
- **SonarCloud:** Code quality gates for smells/bugs

### 3. Network Policies
- Pod-to-pod traffic isolation
- MongoDB locked down: only accessible to user/task services
- Principle of least privilege enforcement

### 4. Automated Database Backups
- Kubernetes CronJob runs daily at midnight
- Executes `mongodump` command
- Saves timestamped backups to PersistentVolumeClaim
- Retains last 3 backups for disaster recovery

### 5. Persistent Storage
- MongoDB attached to PersistentVolumeClaim
- Data survives pod crashes/restarts
- Automatic reconnection on pod replacement

---

## 📁 PROJECT STRUCTURE

```
CA2/
├── user-service/              # User microservice
│   ├── Dockerfile            # Alpine-based Node 18
│   ├── index.js              # Express server + MongoDB
│   └── package.json          # Dependencies
├── task-service/             # Task microservice
│   ├── Dockerfile            # Alpine-based Node 18
│   ├── index.js              # Express server + inter-service calls
│   └── package.json          # Dependencies
├── frontend/
│   └── index.html            # SPA UI
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml
│   ├── mongodb.yaml
│   ├── user-service.yaml
│   ├── task-service.yaml
│   ├── network-policy.yaml
│   └── mongo-backup-cronjob.yaml
├── terraform/                # Infrastructure as Code
│   ├── main.tf              # All K8s resources
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Outputs
│   └── terraform.tfstate    # State file
├── docker-compose.yml        # Local development
├── load-test.js             # k6 load testing script
├── .github/workflows/        # CI/CD pipeline
├── sonar-project.properties  # SonarCloud config
└── Documentation files
    ├── README.md
    ├── Project_Explanation.md
    ├── implementation_plan.md
    ├── RMP_REPORT.md
    └── DEMO_SCRIPT.md
```

---

## ✅ LOCAL DEVELOPMENT SETUP

### Using Docker Compose

```bash
docker-compose up -d --build    # Start all services
docker-compose down             # Stop services
```

### Services Available At
- User-Service: `http://localhost:3000`
- Task-Service: `http://localhost:3001`
- MongoDB: `localhost:27017`

### Docker Compose Configuration
- **Services:** mongodb, user-service, task-service
- **Network:** taskmanager-net (bridge)
- **Volumes:** mongo-data (persistent storage)
- **Dependencies:** Services start in order (mongodb → user-service → task-service)

---

## 📊 GIT HISTORY & STATUS

- **Total Commits:** 15 commits on main branch
- **Latest Commit:** `b87798a - chore: exclude microservice entry points from duplication check`
- **Repository Status:** Clean, aligned with origin/main
- **Branches:** main (current) and origin/main
- **Pending Changes:** RMP_REPORT.md has uncommitted changes
- **Untracked Files:** DEMO_SCRIPT.md, Project_Explanation.md, terraform/.terraform.tfstate.lock.info

---

## 🧪 TESTING & VERIFICATION

### Load Testing (HPA Validation)

```bash
# Forward port from K8s cluster
kubectl port-forward svc/task-service 3001:3001 -n taskmanager

# Run k6 load test (ramps to 300 virtual users)
k6 run load-test.js

# Monitor scaling in real-time
kubectl get hpa -n taskmanager --watch
```

**Expected Result:** task-service scales from 2 to 5 replicas and back down

### Kubernetes Verification

```bash
# Check all running resources
kubectl get all -n taskmanager

# View pod logs
kubectl logs -f deployment/task-service -n taskmanager

# Check HPA status
kubectl get hpa -n taskmanager

# View persistent volumes
kubectl get pvc -n taskmanager
```

---

## 📈 MONITORING (Optional)

### Prometheus + Grafana Stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

**Access at:** `http://localhost:3000`  
**Credentials:** `admin` / `prom-operator`  
**Import Dashboard ID:** `6417` (for pod-level CPU, memory, and network metrics)

---

## ⚙️ KEY TECHNOLOGIES USED

| Layer | Technology |
|-------|-----------|
| **Backend** | Node.js (v18), Express 4.18.2 |
| **Database** | MongoDB 6 |
| **Containerization** | Docker, Docker Compose |
| **Orchestration** | Kubernetes, KinD (local testing) |
| **IaC** | Terraform 1.0+ |
| **CI/CD** | GitHub Actions |
| **Registry** | Docker Hub |
| **Security** | Trivy, npm audit, SonarCloud |
| **Load Testing** | k6 |
| **Monitoring** | Prometheus, Grafana |
| **Frontend** | HTML5, CSS3, Vanilla JavaScript |

---

## 🎓 WHAT THIS PROJECT DEMONSTRATES

✅ **Microservices Architecture** — Inter-service communication with REST APIs  
✅ **Containerization Best Practices** — Multi-stage builds, Alpine images  
✅ **Fully Automated CI/CD Pipeline** — GitHub Actions with matrix strategy  
✅ **Infrastructure as Code** — Terraform for reproducible K8s deployments  
✅ **Kubernetes Deployment** — Rolling updates with zero downtime  
✅ **Auto-scaling** — HPA based on CPU metrics  
✅ **Network Security** — Network Policies enforcing least privilege  
✅ **Data Persistence** — PersistentVolumeClaims for MongoDB  
✅ **Automated Backups** — Daily mongodump via Kubernetes CronJob  
✅ **DevSecOps** — Trivy, npm audit, SonarCloud security scanning  
✅ **Change Management** — Reproducible infrastructure changes  
✅ **Monitoring & Observability** — Prometheus, Grafana, kubectl logs  

---

## 🚀 DEPLOYMENT FLOW

```
Developer commits code to main branch
        ↓
Git push to GitHub
        ↓
GitHub Actions pipeline automatically triggers
        ↓
Stage 1: Build & Test (matrix strategy for both services)
        ↓
Stage 2: Code Quality (SonarCloud)
        ↓
Stage 3: Docker Build
        ↓
Stage 4: Trivy Security Scan (blocks if vulnerabilities found)
        ↓
Stage 5: Push images to Docker Hub
        ↓
Stage 6: Spin up KinD Kubernetes cluster
        ↓
Stage 7: Terraform apply (deploys all infrastructure)
        ↓
Stage 8: Verify rollout success
        ↓
Live Application Running
```

---

## 📝 CHANGE MANAGEMENT PROCESS

| Step | Action | Tool |
|------|--------|------|
| 1 | Developer makes code changes locally | VS Code / IDE |
| 2 | Commit and push to main branch | Git |
| 3 | GitHub detects push to main | GitHub |
| 4 | Pipeline triggers automatically | GitHub Actions |
| 5 | All stages execute sequentially | GitHub Actions workflow |
| 6 | Infrastructure updates via Terraform | Terraform |
| 7 | Kubernetes applies rolling update | kubectl |
| 8 | Application updated with zero downtime | Kubernetes |

**Zero Manual Intervention Required**

---

## 🔐 SECURITY IMPLEMENTATION

### DevSecOps Layers
1. **Build Time:** npm audit catches vulnerable dependencies
2. **Code Quality:** SonarCloud detects code smells and vulnerabilities
3. **Container Scanning:** Trivy scans Docker images for CVEs
4. **Runtime:** Network Policies restrict pod-to-pod communication
5. **Data:** Encryption at rest via MongoDB + Persistent Storage

### Vulnerability Response
- CRITICAL/HIGH vulnerabilities block deployment
- Pipeline fails and notifications sent
- Developers notified to fix security issues
- Deployment resumes only after fix

---

## 💡 PRODUCTION-READY FEATURES

| Feature | Implementation |
|---------|-----------------|
| **High Availability** | Multiple replicas, rolling updates |
| **Auto-recovery** | Kubernetes restarts failed pods |
| **Data Loss Prevention** | PersistentVolumeClaims + daily backups |
| **Quick Rollback** | Instant revert via kubectl rollout undo |
| **Scalability** | HPA scales based on CPU metrics |
| **Cost Optimization** | Auto-scaling down when traffic subsides |
| **Security** | Network policies, vulnerability scanning |
| **Observability** | Monitoring stack with Prometheus/Grafana |

---

## 📚 DOCUMENTATION FILES

- **README.md** — Overview and quick start guide
- **Project_Explanation.md** — Detailed architecture explanation
- **implementation_plan.md** — Implementation blueprint
- **RMP_REPORT.md** — Release Management Plan
- **DEMO_SCRIPT.md** — Live demonstration guide
- **PROJECT_DETAILS.md** — This comprehensive guide

---

## 🎯 ASSIGNMENT REQUIREMENTS MET

✅ **45 Marks - CI/CD Pipeline:**
- GitHub Actions with 7-stage pipeline
- Matrix strategy for concurrent testing
- Automated deployment on push to main
- Security scanning (Trivy) integrated

✅ **Infrastructure as Code:**
- Terraform manages all K8s resources
- Idempotent deployments
- Reproducible infrastructure

✅ **Microservices Architecture:**
- Two independently deployable services
- Inter-service communication demonstrated
- Loose coupling achieved

✅ **10 Marks - Extra Features:**
- Horizontal Pod Autoscaling (HPA)
- DevSecOps vulnerability scanning (Trivy)
- Network policies for security
- Automated database backups

✅ **Change Management:**
- Zero manual steps
- Fully automated pipeline
- Version-controlled infrastructure

---

**Last Updated:** April 22, 2026  
**Repository:** krishnakothagorla04/ca-2-task-manager  
**Current Branch:** main  
**Status:** Production-Ready
