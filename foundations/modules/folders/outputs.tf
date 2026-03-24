output "root_folder_id" {
  description = "Numeric ID of the root folder (without 'folders/' prefix)."
  value       = google_folder.root.folder_id
}

output "root_folder_name" {
  description = "Resource name of the root folder (folders/NUMERIC_ID)."
  value       = google_folder.root.name
}

output "environment_folder_ids" {
  description = "Map of environment key → numeric folder ID."
  value = {
    for k, v in google_folder.environments : k => v.folder_id
  }
}

output "environment_folders" {
  description = "Map of environment key → full resource name."
  value = {
    for k, v in google_folder.environments : k => v.name
  }
}
