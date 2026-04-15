# ==============================================================
# Terraform Main — Infrastructure as Code for Task Manager
# Provisions ALL Kubernetes resources declaratively
#
# Usage:
#   terraform init
#   terraform plan -var="dockerhub_username=YOUR_USERNAME"
#   terraform apply -var="dockerhub_username=YOUR_USERNAME"
#   terraform destroy -var="dockerhub_username=YOUR_USERNAME"
# ==============================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

# ---- Provider: Connect to Kubernetes cluster ----
provider "kubernetes" {
  config_path = var.kube_config_path
}

# ==============================================================
# NAMESPACE
# ==============================================================
resource "kubernetes_namespace" "taskmanager" {
  metadata {
    name = var.namespace
  }
}

# ==============================================================
# MONGODB
# ==============================================================
resource "kubernetes_persistent_volume_claim" "mongo_pvc" {
  metadata {
    name      = "mongo-pvc"
    namespace = kubernetes_namespace.taskmanager.metadata[0].name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = var.mongo_storage_size
      }
    }
  }
  # Don't block Terraform waiting for PVC to bind (provisioner binds async)
  wait_until_bound = false
}


resource "kubernetes_deployment" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace.taskmanager.metadata[0].name
    labels = {
      app = "mongodb"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mongodb"
      }
    }
    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }
      spec {
        container {
          name  = "mongodb"
          image = "mongo:6"
          port {
            container_port = 27017
          }
          volume_mount {
            name       = "mongo-storage"
            mount_path = "/data/db"
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
        volume {
          name = "mongo-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mongo_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace.taskmanager.metadata[0].name
  }
  spec {
    selector = {
      app = "mongodb"
    }
    port {
      port        = 27017
      target_port = 27017
    }
    type = "ClusterIP"
  }
}

# ==============================================================
# USER SERVICE
# ==============================================================
resource "kubernetes_deployment" "user_service" {
  metadata {
    name      = "user-service"
    namespace = kubernetes_namespace.taskmanager.metadata[0].name
    labels = {
      app = "user-service"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "user-service"
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
        max_surge       = "1"
      }
    }
    template {
      metadata {
        labels = {
          app = "user-service"
        }
      }
      spec {
        container {
          name  = "user-service"
          image = "${var.dockerhub_username}/user-service:${var.user_service_image_tag}"
          port {
            container_port = 3000
          }
          env {
            name  = "PORT"
            value = "3000"
          }
          env {
            name  = "MONGO_URI"
            value = "mongodb://mongodb.${var.namespace}.svc.cluster.local:27017/taskmanager"
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "256Mi"
            }
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "user_service" {
  metadata {
    name      = "user-service"
    namespace = kubernetes_namespace.taskmanager.metadata[0].name
  }
  spec {
    selector = {
      app = "user-service"
    }
    port {
      port        = 3000
      target_port = 3000
    }
    type = "ClusterIP"
  }
}

# ==============================================================
# TASK SERVICE
# ==============================================================
resource "kubernetes_deployment" "task_service" {
  metadata {
    name      = "task-service"
    namespace = kubernetes_namespace.taskmanager.metadata[0].name
    labels = {
      app = "task-service"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "task-service"
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
        max_surge       = "1"
      }
    }
    template {
      metadata {
        labels = {
          app = "task-service"
        }
      }
      spec {
        container {
          name  = "task-service"
          image = "${var.dockerhub_username}/task-service:${var.task_service_image_tag}"
          port {
            container_port = 3001
          }
          env {
            name  = "PORT"
            value = "3001"
          }
          env {
            name  = "MONGO_URI"
            value = "mongodb://mongodb.${var.namespace}.svc.cluster.local:27017/taskmanager"
          }
          env {
            name  = "USER_SERVICE_URL"
            value = "http://user-service.${var.namespace}.svc.cluster.local:3000"
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "256Mi"
            }
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "task_service" {
  metadata {
    name      = "task-service"
    namespace = kubernetes_namespace.taskmanager.metadata[0].name
  }
  spec {
    selector = {
      app = "task-service"
    }
    port {
      port        = 3001
      target_port = 3001
    }
    type = "NodePort"
  }
}

# ==============================================================
# HPA — Auto-Scaling for Task Service (Extra Feature)
# ==============================================================
resource "kubernetes_horizontal_pod_autoscaler_v2" "task_service_hpa" {
  metadata {
    name      = "task-service-hpa"
    namespace = kubernetes_namespace.taskmanager.metadata[0].name
  }
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.task_service.metadata[0].name
    }
    min_replicas = 2
    max_replicas = 5
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}
