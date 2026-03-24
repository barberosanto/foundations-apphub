output "admin_members" {
  description = "Members granted apphub.admin."
  value       = [for m in google_project_iam_member.admin : m.member]
}

output "editor_members" {
  description = "Members granted apphub.editor."
  value       = [for m in google_project_iam_member.editor : m.member]
}

output "viewer_members" {
  description = "Members granted apphub.viewer."
  value       = [for m in google_project_iam_member.viewer : m.member]
}

output "dc_admin_members" {
  description = "Members granted designcenter.admin."
  value       = [for m in google_project_iam_member.dc_admin : m.member]
}

output "dc_user_members" {
  description = "Members granted designcenter.user."
  value       = [for m in google_project_iam_member.dc_user : m.member]
}

output "folder_bindings" {
  description = "Map of binding key → { member, role, folder }."
  value = {
    for k, v in google_folder_iam_member.access : k => {
      member = v.member
      role   = v.role
      folder = v.folder
    }
  }
}

# =============================================================================
# DevOps Service Account
# =============================================================================
output "devops_sa_email" {
  description = "Email of the DevOps service account."
  value       = var.create_devops_sa ? google_service_account.devops[0].email : null
}

output "devops_sa_id" {
  description = "Fully-qualified resource ID of the DevOps service account."
  value       = var.create_devops_sa ? google_service_account.devops[0].id : null
}

output "devops_sa_roles" {
  description = "List of IAM roles granted to the DevOps service account."
  value       = [for r in google_folder_iam_member.devops_roles : r.role]
}
