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

# Create App Engine application
resource "google_app_engine_application" "app" {
  project     = var.project_id
  location_id = "asia-southeast1"  # Use existing location
  
  depends_on = [google_project_service.appengine_api]
}

# Cloud Build trigger for main branch
resource "google_cloudbuild_trigger" "main_trigger" {
  name        = "deploy-on-main-push"
  description = "Trigger to build and deploy when pushing to main branch"
  location    = "asia-northeast1"
  
  repository_event_config {
    repository = "projects/game-460004/locations/asia-northeast1/connections/my-github-connection/repositories/go-terra-2"
    
    push {
      branch = "^main$"
    }
  }
  
  filename = "cloudbuild.yaml"
  
  depends_on = [google_project_service.cloudbuild_api]
}