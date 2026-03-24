output "enabled_apis" {
  description = "List of APIs that were enabled."
  value       = [for api in google_project_service.this : api.service]
}

output "services" {
  description = "Map of service name → google_project_service resource (for depends_on)."
  value       = google_project_service.this
}
