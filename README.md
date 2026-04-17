# Enterprise DevOps & Microservices Task Manager
**Continuous Assessment 2 (CA2) Final Project**

---

## 1. Project Overview & Objective
This project is an enterprise-grade, DevOps-centric **Task Manager Application**. The core objective of this project is not just to build an application, but to orchestrate, automate, and secure its entire lifecycle. 

The system leverages a **Microservices Architecture** entirely provisioned via **Infrastructure as Code (Terraform)**, deployed to **Kubernetes**, and strictly automated through a **GitHub Actions CI/CD Pipeline**. It satisfies advanced enterprise requirements including Zero-Downtime deployments, DevSecOps vulnerability scanning, Local Storage Persistence, and mathematically driven Auto-Scaling.

---

## 2. The Application Architecture (Microservices)
Instead of a traditional monolithic backend, the application logic is separated into decoupled services that communicate synchronously over the network.

### 2.1 The Services
* **User-Service (Node.js/Express):** Handles user registration, secure authentication, and session generation.
* **Task-Service (Node.js/Express):** Handles the creation, status updating, and deletion of tasks.
* **MongoDB (Database):** A centralized NoSQL database utilized dynamically by both services via Mongoose to maintain dedicated collections (`users` and `tasks`).
* **Frontend SPA:** A single-page HTML/JS application (Vanilla JS) that handles Authentication (Sign Up/Sign In), Session Persistence (via `localStorage`), and strict **Data Isolation** (users can only view and manage tasks belonging directly to their secure Session ID).

### 2.2 Proof of Inter-Service Communication
When a user attempts to create a task via the Task-Service, the Task-Service does not blindly insert it into the database. Instead, the Task-Service initiates a synchronous `HTTP GET` REST API request out across the Kubernetes network to the User-Service to cryptographically validate that the user exists. If the User-Service denies the existence of the user, the task creation halts.

---

## 3. Continuous Integration & Continuous Deployment (CI/CD)
The deployment is entirely disconnected from manual human interaction. Code pushed to the `main` branch on GitHub instantly triggers a 140-line `deploy.yml` CI/CD Pipeline.

### 3.1 Unification via Matrix Strategy
Rather than maintaining split pipelines, the project uses a **Matrix Build Strategy** to uniformly loop over both microservices concurrently, ensuring both services receive identical testing and security enforcement.

### 3.2 Pipeline Flow
1. **Build & Test:** Provisions Node.js and installs dependencies.
2. **Dockerization:** Builds lightweight, multi-stage `node:18-alpine` containers.
3. **DevSecOps (Trivy):** An AquaSecurity Trivy scan halts the pipeline if `CRITICAL` or `HIGH` vulnerabilities are detected inside the freshly built Docker image.
4. **Push:** Uploads the authorized images to Docker Hub safely.
5. **Infrastructure Orchestration:** Spins up a KinD Kubernetes cluster dynamically within the GitHub server, downloads the Terraform CLI, and automatically executes `terraform apply --auto-approve` to patch the live architectural state.

---

## 4. Infrastructure as Code (Terraform) & Kubernetes
All cloud infrastructure is declared mathematically inside `terraform/main.tf` to achieve **Idempotency** (the ability to confidently destroy and perfectly reconstruct the cluster on demand).

### 4.1 Deployment Strategy (Rolling Update)
The Terraform scripts explicitly dictate a **RollingUpdate** strategy with `maxUnavailable: 1` and `maxSurge: 1`. 
* **Justification:** If an update is pushed, Kubernetes replaces the pods one-by-one, guaranteeing absolute **Zero-Downtime**. If a catastrophic bug is detected, Kubernetes supports instant rollbacks via `kubectl rollout undo` to revert to previous ReplicaSets.

### 4.2 Persistent Storage
By default, containers are stateless. The project utilizes a `kubernetes_persistent_volume_claim` (PVC) attached directly to the MongoDB cluster. 
* **Justification:** If the database pod suffers a fatal crash, the actual data is preserved safely on a protected volume and seamlessly re-attached to the replacement pod upon reboot.

---

## 5. Extra DevOps Features Implemented
To ensure enterprise-level compliance, two extra features were explicitly engineered into the core infrastructure:

1. **Security Vulnerability Scanning:** Integrated directly as a blocking phase in the CI/CD pipeline using Trivy.
2. **Mathematical Auto-Scaling:** A **Horizontal Pod Autoscaler (HPA)** was added to the Task-Service via Terraform. It actively monitors CPU utilziation. If organic traffic spikes cpu usage past 70%, the cluster automatically clones the Task-Service from 2 replicas up to 5 replicas dynamically to handle the load, scaling back down when traffic subsides to save computational cost.

---

## 6. How to Run & Verify Locally
For local development, testing, and live presentation styling, you do not need to run the full Kubernetes cluster. 

Ensure Docker Desktop is running, then use the multi-container configuration tool:
1. Open up a terminal directory containing the project.
2. Build and start the architecture in the background:
   ```bash
   docker-compose up -d --build
   ```
3. Open `frontend/index.html` in any web browser to simulate the client application.
4. When finished, safely tear down the containers:
   ```bash
   docker-compose down
   ```
