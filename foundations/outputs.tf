# =============================================================================
# Outputs — pass-through from modules
# =============================================================================

# --- Project ---
output "project_id" {
  description = "Management project ID."
  value       = module.project.project_id
}

output "project_number" {
  description = "Management project number."
  value       = module.project.project_number
}

# --- Folders ---
output "root_folder_id" {
  description = "Numeric ID of the root (projeto) folder."
  value       = module.folders.root_folder_id
}

output "root_folder_name" {
  description = "Resource name of the root folder (folders/ID)."
  value       = module.folders.root_folder_name
}

output "environment_folder_ids" {
  description = "Map of environment key → numeric folder ID."
  value       = module.folders.environment_folder_ids
}

# --- Spoke Projects ---
output "env_project_ids" {
  description = "Map of spoke project key → project ID."
  value       = module.env_projects.project_ids
}

output "env_project_numbers" {
  description = "Map of spoke project key → project number."
  value       = module.env_projects.project_numbers
}

# --- APIs ---
output "enabled_apis" {
  description = "List of APIs enabled on the management project."
  value       = module.apis.enabled_apis
}

# --- App Hub (gerenciado pelo ADC via console) ---
# output "application_ids" {
#   description = "Map of application_id → full resource name."
#   value       = module.apphub.application_ids
# }
#
# output "folder_display_name" {
#   description = "Display name of the app-enabled folder."
#   value       = module.apphub.folder_display_name
# }

# --- Service Projects (gerenciado pelo ADC boundary) ---
# output "service_project_attachments" {
#   description = "Map of spoke key → attachment resource name."
#   value       = module.service_projects.attachments
# }

# --- IAM ---
output "iam_admins" {
  description = "Members granted apphub.admin."
  value       = module.iam.admin_members
}

output "iam_editors" {
  description = "Members granted apphub.editor."
  value       = module.iam.editor_members
}

output "iam_viewers" {
  description = "Members granted apphub.viewer."
  value       = module.iam.viewer_members
}

output "iam_dc_admins" {
  description = "Members granted designcenter.admin."
  value       = module.iam.dc_admin_members
}

output "iam_dc_users" {
  description = "Members granted designcenter.user."
  value       = module.iam.dc_user_members
}

output "folder_iam_bindings" {
  description = "Map of all folder-level IAM bindings (group → folder → role)."
  value       = module.iam.folder_bindings
}

# --- Design Center ---
output "design_center_spaces" {
  description = "Map of Design Center space IDs created."
  value       = module.design_center.space_ids
}

# --- DevOps Service Account ---
output "devops_sa_email" {
  description = "Email of the DevOps service account."
  value       = module.iam.devops_sa_email
}

output "devops_sa_id" {
  description = "Fully-qualified resource ID of the DevOps service account."
  value       = module.iam.devops_sa_id
}

output "devops_sa_roles" {
  description = "List of IAM roles granted to the DevOps service account."
  value       = module.iam.devops_sa_roles
}
