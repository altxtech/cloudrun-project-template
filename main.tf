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
  default     = "us-west1"
}

variable "service_name" {
  description = "Name of the service. Defines the resource names of both the AR repository and Cloud Run service."
}

variable "env" {
  description = "Name of the environment (e.g dev or prod)"
  default     = "dev"
}

variable "image" {
  description = "Image to deploy"
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

resource "google_secret_manager_secret" "secret" {
  secret_id = "${var.service_name}-${var.env}-secret"

  replication {
	  auto{}
  }
}

resource "google_secret_manager_secret_version" "secret-version" {
  secret = google_secret_manager_secret.secret.id

  secret_data = "secret-data"
}

data "google_iam_policy" "secret_access" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:${google_service_account.sa.email}",
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = var.project_id
  secret_id   = google_secret_manager_secret.secret.name
  policy_data = data.google_iam_policy.secret_access.policy_data
}


# 2.3 DATABASE

resource "google_firestore_database" "database" {
  project                 = var.project_id
  name                    = "${var.service_name}-${var.env}-db"
  location_id             = var.region
  type                    = "FIRESTORE_NATIVE"
  delete_protection_state = var.env == "prod" ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"
}

# Give service account access to the database
resource "google_project_iam_binding" "db_access" {
  project = var.project_id
  role    = "roles/datastore.user"
  members = [
    "serviceAccount:${google_service_account.sa.email}",
  ]
  condition {
    title      = "Limited to the proper database"
    expression = "resource.name==\"${google_firestore_database.database.id}\""
  }
}


# 2.6 SERVICE

# Define a Google Cloud Run service
resource "google_cloud_run_service" "app" {
  name     = "${var.service_name}-${var.env}"
  location = var.region # Replace with your desired region

  template {
    spec {
      containers {

        image = var.image
        env {
          name  = "ENV"
          value = var.env
        }
        env {
          name  = "DATABASE_ID"
          value = google_firestore_database.database.id
        }
        env {
          name  = "SECRET_ID"
          value = google_secret_manager_secret.secret.id
        }
      }
      service_account_name = google_service_account.sa.email
    }
  }
}

/*
# 2.6 EXPOSE THE SERVICE

# This block will make the service public
# Uncomment this block for public facing services or testing enviroments

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_service.app.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

# Output the service URL
output "service_url" {
  value = google_cloud_run_service.app.status[0].url
}
*/
