# Release Management Plan (RMP) — Task Manager

## 1. Introduction
This document presents the Release Management Plan for a microservices-based Task Manager application, designed and deployed following enterprise DevOps best practices. The system demonstrates Infrastructure as Code, fully automated CI/CD, and cloud-native deployment strategies.

## 2. System Architecture

### 2.1 Microservices Overview
The application is decomposed into two independently deployable services:

- **user-service:** Manages user accounts (CRUD). Exposes a REST API consumed by the task-service for user validation.
- **task-service:** Manages tasks (CRUD). Before creating a task, it validates the assigned user by making an HTTP request to the user-service — demonstrating true inter-service communication.
- **MongoDB:** A single database instance with separate collections (`users`, `tasks`).

### 2.2 Architecture Diagram
*(Insert the architecture diagram from the README or create a visual in your presentation)*

### 2.3 Justification of Architecture Decisions

| Decision | Justification |
|----------|---------------|
| **Microservices over Monolith** | Each service can be developed, deployed, and scaled independently. If user-service fails, task-service remains partially available (graceful degradation). |
| **Node.js (Express)** | Lightweight, non-blocking I/O model ideal for REST microservices. Large ecosystem and fast development cycle. |
| **MongoDB** | Schema-flexible NoSQL database suited for rapid prototyping and JSON-native data. Aligns naturally with Node.js. |
| **REST for inter-service communication** | Simple, stateless, and widely understood protocol. Sufficient for synchronous validation calls between services. |

## 3. CI/CD Pipeline (45 Marks)

### 3.1 Pipeline Overview
The CI/CD pipeline is implemented using **GitHub Actions** and is triggered automatically on every `git push` to the `main` branch. No manual intervention is required at any stage.

### 3.2 Pipeline Stages

| Stage | Action | Tool |
|-------|--------|------|
| 1. Build & Test | Install dependencies, run tests | Node.js, npm |
| 2. Docker Build | Build container images for both services | Docker |
| 3. Security Scan | Scan images for vulnerabilities | Trivy |
| 4. Push | Push images to Docker Hub | Docker Hub |
| 5. Deploy | Apply Kubernetes manifests | kubectl |
| 6. Verify | Confirm rollout success | kubectl rollout status |

### 3.3 Justification

| Decision | Justification |
|----------|---------------|
| **GitHub Actions** | Tightly integrated with the Git repository. Free tier sufficient for this project. YAML-based declarative pipelines are reproducible and version-controlled. |
| **Docker Hub** | Industry-standard public registry. Simplifies image distribution for Kubernetes. |
| **Trivy** | Open-source, fast vulnerability scanner. Integrates seamlessly into CI/CD without additional infrastructure. |

## 4. Infrastructure as Code (Terraform)

### 4.1 What Terraform Manages
Terraform provisions all Kubernetes resources declaratively:
- Namespace, Deployments, Services, PVCs, and HPA

### 4.2 Reproducibility
The system can be:
- **Created:** `terraform apply`
- **Destroyed:** `terraform destroy`
- **Re-created:** `terraform apply` again

This satisfies the requirement for fully automated, reproducible infrastructure provisioning.

### 4.3 Justification

| Decision | Justification |
|----------|---------------|
| **Terraform over manual kubectl** | Declarative state management. Terraform tracks what exists and only applies differences. The entire infrastructure is version-controlled. |
| **Kubernetes provider** | Allows managing K8s resources directly without shell scripts, ensuring idempotency. |

## 5. Deployment Strategy

### 5.1 Rolling Updates
Both services use a **RollingUpdate** strategy configured in their Kubernetes Deployments:
- `maxUnavailable: 1` — At most one pod is taken down at a time
- `maxSurge: 1` — At most one extra pod is created during the update

**Result:** Users experience zero downtime during deployments.

### 5.2 Rollback Strategy
Kubernetes maintains previous ReplicaSets. If a deployment fails:
```bash
kubectl rollout undo deployment/task-service -n taskmanager
```
This instantly reverts to the last known-good state.

## 6. Change Management

### 6.1 How Updates Are Deployed
```
Developer makes code change
        ↓
Git push to main branch
        ↓
GitHub Actions pipeline triggers automatically
        ↓
Build → Test → Docker Build → Security Scan → Push → Deploy
        ↓
Kubernetes performs rolling update
        ↓
New version is live (zero downtime)
```

**Key Point:** There are zero manual steps between code change and live deployment. The pipeline is fully automated and reproducible.

## 7. Scaling Strategy

### 7.1 Horizontal Pod Autoscaler (HPA)
The task-service is configured with an HPA:
- **Min replicas:** 2
- **Max replicas:** 5
- **Trigger:** CPU utilization exceeds 70%

### 7.2 Justification
Auto-scaling ensures the system can handle traffic spikes without manual intervention, and scales back down to save resources during low-traffic periods.

## 8. Backup & Recovery Strategy

### 8.1 Backup Plan
- **Tool:** `mongodump` — creates binary exports of the MongoDB database
- **Frequency:** Scheduled daily (via cron job or Kubernetes CronJob)
- **Storage:** Backups stored in a persistent volume or cloud storage (e.g., S3)

### 8.2 Recovery Plan
- **Tool:** `mongorestore` — restores from a `mongodump` backup
- **Process:**
  1. Identify the most recent backup
  2. Scale down task-service and user-service
  3. Run `mongorestore` against the MongoDB instance
  4. Scale services back up
  5. Verify data integrity

### 8.3 Kubernetes-Level Recovery
- MongoDB uses a PersistentVolumeClaim (PVC), ensuring data survives pod restarts
- Container images are stored in Docker Hub, so any service can be redeployed from scratch

## 9. Security

### 9.1 Container Security
- **Trivy scanning** in CI/CD catches known vulnerabilities before images are deployed
- **Alpine-based images** minimize attack surface

### 9.2 Network Security
- Services communicate internally via Kubernetes ClusterIP (not exposed externally)
- Only task-service is exposed via NodePort for demo purposes

## 10. Monitoring & Logging

### 10.1 Current Implementation
- **Application logging:** Morgan HTTP logger in both services
- **Kubernetes logs:** `kubectl logs deployment/task-service -n taskmanager`
- **Health checks:** `/health` endpoints used by Kubernetes readiness and liveness probes

### 10.2 Future Improvements
- Prometheus + Grafana for metrics dashboards
- ELK/EFK stack for centralized log aggregation

## 11. Evaluation

### 11.1 Performance
- Lightweight Node.js services start in under 2 seconds
- Health probes ensure traffic only routes to ready pods

### 11.2 Cost
- Minikube: Free for local development
- Cloud: Minimal cost (2 small pods + 1 DB = ~$20/month on DigitalOcean)

### 11.3 Scalability
- HPA enables automatic horizontal scaling
- Microservice architecture allows independent scaling of each service

### 11.4 Ease of Use
- `docker-compose up` for local dev
- `terraform apply` for full deployment
- One git push triggers entire pipeline

### 11.5 Trade-offs
| Advantage | Limitation |
|-----------|-----------|
| Zero-downtime deployments | Adds complexity vs. simple server deployment |
| Full automation | Requires initial setup of secrets and cluster |
| Reproducible infrastructure | Learning curve for Terraform + K8s |
