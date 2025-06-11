# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.location_id
}

# Enable required APIs
resource "google_project_service" "cloudbuild_api" {
  service = "cloudbuild.googleapis.com"
  
  disable_dependent_services = true
}

resource "google_project_service" "appengine_api" {
  service = "appengine.googleapis.com"
  
  disable_dependent_services = true
}

resource "google_project_service" "secretmanager_api" {
  service = "secretmanager.googleapis.com"
  
  disable_dependent_services = true
}

# Grant Cloud Build service account permissions for Secret Manager
resource "google_project_iam_member" "cloudbuild_secretmanager_create" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  
  depends_on = [google_project_service.secretmanager_api]
}

resource "google_project_iam_member" "cloudbuild_secretmanager_admin" {
  project = var.project_id
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  
  depends_on = [google_project_service.secretmanager_api]
}

# Get project data
data "google_project" "project" {
  project_id = var.project_id
}

# Create custom service account for Cloud Build
resource "google_service_account" "cloudbuild_service_account" {
  account_id   = "cloudbuild-sa"
  display_name = "Cloud Build Service Account"
  description  = "Custom service account for Cloud Build triggers"
}

# Grant necessary permissions to the custom service account
resource "google_project_iam_member" "cloudbuild_sa_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_appengine_deployer" {
  project = var.project_id
  role    = "roles/appengine.deployer"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

# Create App Engine application
resource "google_app_engine_application" "app" {
  project     = var.project_id
  location_id = "asia-southeast1"  # Use existing location
  
  depends_on = [google_project_service.appengine_api]
}

# Cloud Build trigger for main branch
resource "google_cloudbuild_trigger" "main_trigger" {
  name         = "deploy-on-main-push"
  description  = "Trigger to build and deploy when pushing to main branch"
  project      = var.project_id
  location     = "us-central1"
  service_account = google_service_account.cloudbuild_service_account.id

  repository_event_config {
    repository = "projects/game-460004/locations/us-central1/connections/my-github-connection-us/repositories/go-terra-2-us"
    
    push {
      branch = "^main$"
    }
  }
  
  filename = "cloudbuild.yaml"
  
  depends_on = [google_project_service.cloudbuild_api, google_service_account.cloudbuild_service_account]
}