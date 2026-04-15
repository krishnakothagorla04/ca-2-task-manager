# 📋 Task Manager — Enterprise DevOps System (CA2)

A microservices-based Task Manager deployed via a fully automated CI/CD pipeline with Infrastructure as Code.

## 🏗️ Architecture

```
┌────────────┐       REST        ┌────────────┐
│  Frontend   │ ──────────────── │ task-service│──┐
│  (HTML/JS)  │                  │  :3001      │  │ validates user
└────────────┘                   └─────────────┘  │
       │                               │          │
       │                               ▼          │
       │                         ┌──────────┐     │
       │                         │ MongoDB  │     │
       │                         │  :27017  │     │
       │                         └──────────┘     │
       │                               ▲          │
       │          REST           ┌─────────────┐  │
       └────────────────────────►│ user-service│◄─┘
                                 │  :3000      │
                                 └─────────────┘
```

## ⚙️ Tech Stack

| Layer            | Tool                         |
|------------------|------------------------------|
| Backend          | Node.js (Express)            |
| Database         | MongoDB                      |
| Containerization | Docker                       |
| CI/CD            | GitHub Actions               |
| Orchestration    | Kubernetes (Minikube)        |
| IaC              | Terraform                    |
| Registry         | Docker Hub                   |
| Security Scan    | Trivy                        |

## 🚀 Quick Start (Local Development)

### Prerequisites
- Docker Desktop running
- Node.js 18+

### Run with Docker Compose
```bash
docker-compose up --build
```

Services will be available at:
- **User Service:** http://localhost:3000
- **Task Service:** http://localhost:3001
- **Frontend:**     Open `frontend/index.html` in a browser

### Test the APIs
```bash
# Create a user
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'

# Create a task (use the user _id from above)
curl -X POST http://localhost:3001/tasks \
  -H "Content-Type: application/json" \
  -d '{"userId":"<USER_ID>","title":"Setup CI/CD","description":"Automate deployment"}'

# Get all tasks
curl http://localhost:3001/tasks
```

## ☸️ Kubernetes Deployment (Minikube)

```bash
# Start Minikube
minikube start

# Apply all manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mongodb.yaml
kubectl apply -f k8s/user-service.yaml
kubectl apply -f k8s/task-service.yaml

# Check status
kubectl get all -n taskmanager
```

## 🛠️ Terraform (IaC)

```bash
cd terraform
terraform init
terraform plan -var="dockerhub_username=YOUR_USERNAME"
terraform apply -var="dockerhub_username=YOUR_USERNAME"

# Tear down everything
terraform destroy -var="dockerhub_username=YOUR_USERNAME"
```

## 🔁 CI/CD Pipeline

The GitHub Actions pipeline (`.github/workflows/deploy.yml`) runs automatically on push to `main`:

1. **Build & Test** — Install deps, run tests
2. **Docker Build + Security Scan** — Build images, scan with Trivy
3. **Push** — Push to Docker Hub
4. **Deploy** — Apply K8s manifests, verify rollout

### Required GitHub Secrets
| Secret              | Description                     |
|---------------------|---------------------------------|
| `DOCKERHUB_USERNAME`| Your Docker Hub username        |
| `DOCKERHUB_TOKEN`   | Docker Hub access token         |
| `KUBE_CONFIG`       | Base64-encoded kubeconfig file  |

## 📈 Extra Features
1. **Auto-scaling (HPA)** — task-service scales 2→5 replicas at 70% CPU
2. **Security Scanning** — Trivy scans Docker images in CI/CD

## 📝 Project Structure

```
CA2/
├── user-service/          # User microservice
│   ├── index.js
│   ├── package.json
│   └── Dockerfile
├── task-service/          # Task microservice
│   ├── index.js
│   ├── package.json
│   └── Dockerfile
├── frontend/              # Demo UI
│   └── index.html
├── k8s/                   # Kubernetes manifests
│   ├── namespace.yaml
│   ├── mongodb.yaml
│   ├── user-service.yaml
│   └── task-service.yaml
├── terraform/             # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .github/workflows/     # CI/CD pipeline
│   └── deploy.yml
├── docker-compose.yml     # Local development
└── README.md
```
