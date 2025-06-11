variable "project_id" {
  description = "The GCP project ID."
  type        = string
  default = "game-460004"
}

variable "location_id" {
  description = "The App Engine region."
  type        = string
  default     = "us-central1" # Hoặc region bạn muốn
}