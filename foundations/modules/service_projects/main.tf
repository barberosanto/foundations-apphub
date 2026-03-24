# =============================================================================
# Hub-Spoke — Service Project Attachments
# =============================================================================
resource "google_apphub_service_project_attachment" "this" {
  for_each = var.service_projects

  project                       = var.project_id
  service_project_attachment_id = each.value.project_id
}
