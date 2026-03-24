output "project_ids" {
  description = "Map of project key → project ID."
  value = {
    for k, v in google_project.this : k => v.project_id
  }
}

output "project_numbers" {
  description = "Map of project key → project number."
  value = {
    for k, v in google_project.this : k => v.number
  }
}

output "service_project_map" {
  description = "Map ready to feed into service_projects module (key → {project_id, number})."
  value = {
    for k, v in google_project.this : k => {
      project_id = v.project_id
      number     = v.number
    }
  }
}
