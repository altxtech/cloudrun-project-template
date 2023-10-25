# backend
terraform {
  backend "gcs" {
    bucket = "terraform-02947138"
    prefix = "cloud-run-template"
  }
}


# VARIABLES

variable "project_id" {
  description = "Google Cloud Project ID"
}

variable "region" {
  description = "Google Cloud region for Cloud Run"
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the service. Defines the resource names of both the AR reposityr and Cloud Run service."
  default     = "us-central1"
}

variable "env" {
  description = "Name of the environment (e.g dev or prod)"
  default     = "dev"
}


# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}


# 1. RESOURCES

# Define the service svc
resource "google_service_account" "sa" {
  account_id   = "my-service-account"
  display_name = "A service account that only Jane can interact with"
}


/*
	SECRETS
	Copy and paste this block for each secret you service uses
*/

variable "secret_id" {
	description  = "Name of the secret to mount to the app"
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:${google_service_account.sa.name}",
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project = var.project_id
  secret_id = var.secret_id 
  policy_data = data.google_iam_policy.admin.policy_data
}


/*
	FIRESTORE COLLECTIONS
	Copy and paste this block for every collection your service uses
*/


# Define a Google Cloud Run service
resource "google_cloud_run_service" "app" {
  name     = "${var.service_name}-${var.environment}"
  location = var.region        # Replace with your desired region

  template {
    spec {
      containers {
        image = "${var.location}-docker.pkg.dev/${var.project}/${var.service_name}-${var.env}/${var.service_name}:latest"
      }
	  service_account_name = google_service_account.sa.name
    }
	volume_mounts {
		name = var.secret_name
		mount_paht = "/mnt/secrets/${var.secret_name}"
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

