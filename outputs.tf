output "app_engine_url" {
  description = "The URL of the deployed App Engine application"
  value       = "https://${google_app_engine_application.app.default_hostname}"
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "trigger_id" {
  description = "The ID of the Cloud Build trigger"
  value       = google_cloudbuild_trigger.main_trigger.id
}