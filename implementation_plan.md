# Enterprise DevOps System: Task Manager Detailed Plan

This is the finalized blueprint for the CA2 assignment, directly answering the provided requirements.

## 🎯 1. Goal Overview
Design and implement a microservices-based Task Manager application deployed via a:
*   Fully automated CI/CD pipeline
*   Infrastructure as Code (Terraform)
*   Kubernetes-based deployment
*   And document everything in a Release Management Plan (RMP).

## 🏗️ 2. Architecture (FINAL)
**Microservices Design:**
1.  **`task-service` (Node.js – Express)**
    *   *Handles:* Create task, View tasks, Update status, Delete task
2.  **`user-service` (Node.js – Express)**
    *   *Handles:* Create user, Get users
3.  **Database (MongoDB)**
    *   *Collections:* `users`, `tasks`

**Service Communication:**
*   `task-service` → `user-service` (REST call)
*   *Detail:* Task service validates the user exists in `user-service` before creating a task. This demonstrates true microservice interaction.

**Frontend (Minimal):**
*   Simple HTML/JS UI (or Postman collections) to demonstrate the app working without needing complex frontend code.

## ⚙️ 3. Technology Stack List
*   **Backend:** Node.js (Express)
*   **Database:** MongoDB
*   **Containerization:** Docker
*   **CI/CD:** GitHub Actions
*   **Orchestration:** Kubernetes (Minikube-compatible manifests)
*   **IaC:** Terraform (lightweight usage for Kubernetes deployment)
*   **Registry:** Docker Hub

## 🛠️ 4. Infrastructure as Code (IaC)
**Terraform Role:**
*   Manage Kubernetes resources/deployment configs using the `kubernetes` provider.
*   Ensure the system is **Reproducible**, **Destroyable**, and **Re-creatable**.
*   *Commands to feature in report:* `terraform apply` and `terraform destroy`.

## 🔁 5. CI/CD Pipeline (CORE – 45 Marks)
**Trigger:** On `git push` to the main branch.

**Pipeline Stages:**
1.  **Build & Test:** Install JS dependencies (`npm install`), run basic tests.
2.  **Docker Build:** Build images for both `task-service` and `user-service`.
3.  **Security Scan (Extra Feature 1):** Use **Trivy** to scan built Docker images for vulnerabilities.
4.  **Push Images:** Push secured images to Docker Hub.
5.  **Deploy (Automated):** Automatically apply Kubernetes manifests (or trigger Terraform `apply` within the GitHub action).

## ☸️ 6. Kubernetes Deployment Strategy
**Components:**
*   **Deployments:** `task-service`, `user-service`, `mongodb`
*   **Services:** Internal ClusterIP for comms, NodePort/LoadBalancer for external access.

**Deployment Strategy: Rolling Updates**
*   Ensures no downtime with gradual replacement of pods.

**Rollback Strategy:**
*   Leveraging Kubernetes ReplicaSets to return to a previous state on failure.

## 📈 7. Extra Features (10 Marks)
1.  **Auto-scaling:** Kubernetes HPA, scaling the `task-service` based on CPU thresholds.
2.  **Security Scanning:** Embedded Trivy in the CI/CD pipeline.

## 💾 8. Backup & Recovery Strategy
*   **Plan:** Explain periodic MongoDB backup strategy using `mongodump` stored locally or on the cloud.
*   **Recovery:** Explain recovery pipeline utilizing `mongorestore`.

## 📊 9. Monitoring & Logging
*   Use `kubectl logs` for core requirement.
*   *(Optional)* Include a note about Prometheus + Grafana if time permits.

## 📝 10. RMP Presentation & Change Management
The final report structure will reflect this exact flow (Code Change → Git Push → CI/CD Pipeline → Build → Deploy → Live System) ensuring "Zero manual steps".

---
## ⚠️ User Approval
Please review this finalized plan above. If it perfectly matches your expectations, approve it, and I will begin generating the exact code files (`package.json`, `index.js`, `Dockerfiles`, `main.tf`, `.github/workflows/deploy.yml` and the k8s manifests).
