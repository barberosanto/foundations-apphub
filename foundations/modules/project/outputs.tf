output "project_id" {
  description = "The project ID of the created management project."
  value       = google_project.this.project_id
}

output "project_number" {
  description = "The numeric project number."
  value       = google_project.this.number
}

output "project_name" {
  description = "The display name of the project."
  value       = google_project.this.name
}
