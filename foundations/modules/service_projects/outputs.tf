output "attachments" {
  description = "Map of spoke key → attachment resource name."
  value = {
    for k, v in google_apphub_service_project_attachment.this : k => v.name
  }
}
