# backend
terraform {
  backend "gcs" {
    bucket = "terraform-02947138"
    prefix = "cloud-run-template"
  }
}

# Define variables
variable "project_id" {
  description = "Google Cloud Project ID"
}

variable "region" {
  description = "Google Cloud region for Cloud Run"
  default     = "us-central1"
}

# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Define a Google Cloud Run service
resource "google_cloud_run_service" "example_service" {
  name     = "example-service" # Replace with your service name
  location = var.region        # Replace with your desired region

  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/titanium-tape-397220/cloud-run-source-deploy/hello-test:latest" # Replace with your Docker image URL
      }
    }
  }
}

# Expose the service
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.example_service.name
  location = google_cloud_run_service.example_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output the service URL
output "service_url" {
  value = google_cloud_run_service.example_service.status[0].url
}

