/*

This is a model will deploy:

- A cloud run service
- A corresponding artifact registry repository for that service
- Configure access to a predeployed secret on the same account
- A firestore database and access

This is meant to be a good starting point for any basic cloud run project.  
Edit this model as needed (e.g add more secrets, change the database, etc...)

Obs: Terrafomr won't handle the deployment of new revisions to the service.
There should be a separate workflow to build, push and deploy the images.

*/

# backend
terraform {
  backend "gcs" {
    bucket = "terraform-02947138"
    prefix = "cloud-run-template"
  }
}


# 1 VARIABLES

variable "project_id" {
  description = "Google Cloud Project ID"
}

variable "region" {
  description = "Google Cloud region"
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the service. Defines the resource names of both the AR repository and Cloud Run service."
  default     = "us-central1"
}

variable "env" {
  description = "Name of the environment (e.g dev or prod)"
  default     = "dev"
}

variable "secret_id" {
  description = "Name of the secret to mount to the app"
}

# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}


# 2 RESOURCES

# 2.1 SERVICE ACCOUNT

resource "google_service_account" "sa" {
  account_id   = "${var.service_name}-${var.env}-svc"
  display_name = "Service account for cloud run"
}

# 2.2 SECRET

data "google_iam_policy" "secret_access" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:${google_service_account.sa.name}",
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = var.project_id
  secret_id   = var.secret_id
  policy_data = data.google_iam_policy.admin.policy_data
}


# 2.3 DATABASE

resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "${var.service_name}-${var.env}-db"
  location_id = "nam5"
  type        = "FIRESTORE_NATIVE"
}

# Give service account access to the database
data "google_iam_policy" "db_access" {
  binding {
    role = "roles/datastore.user"
    members = [
      "serviceAccount:${google_service_account.sa.name}",
    ]
    condition {
      title      = "Limited to the proper database"
      expression = "resource.name=${google_firestore_database.id}"
    }
  }
}

# How to bind the policy?

# 2.4 REPOSITORY
# Delete this block if you intend to pull images from somewhere else
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${var.service_name}-${var.env}"
  description   = "Repository for Cloud Run Images"
  format        = "DOCKER"
}

# 2.5 SERVICE

# Define a Google Cloud Run service
resource "google_cloud_run_service" "app" {
  name     = "${var.service_name}-${var.env}"
  location = var.region # Replace with your desired region

  template {
    spec {
      containers {
        image = "${google_artifact_registry_repository.repo.id}/${var.service_name}:latest"
      }
      service_account_name = google_service_account.sa.name
    }
    volume_mounts {
      name       = var.secret_name
      mount_paht = "/mnt/secrets/${var.secret_name}"
    }
    env {
      name  = "ENV"
      value = var.env
    }
  }
}

# 2.6 EXPOSE THE SERVICE
# DELETE THIS
# Set proper permissions for production

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

# Output the service URL
output "service_url" {
  value = google_cloud_run_service.example_service.status[0].url
}
