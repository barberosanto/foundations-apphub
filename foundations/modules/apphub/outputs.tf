output "application_ids" {
  description = "Map of application_id → full resource name."
  value = {
    for k, v in google_apphub_application.this : k => v.name
  }
}

output "folder_display_name" {
  description = "Display name of the app-enabled folder."
  value       = data.google_folder.scope.display_name
}
