# =============================================================================
# Management Project — Bootstrap
# =============================================================================
# Creates the management project, links billing, and enables essential APIs.
# This is the first resource created in a fresh GCP organization.
# =============================================================================

resource "google_project" "this" {
  name            = var.project_name != "" ? var.project_name : var.project_id
  project_id      = var.project_id
  org_id          = var.folder_id == "" ? var.org_id : null
  folder_id       = var.folder_id != "" ? var.folder_id : null
  billing_account = var.billing_account

  auto_create_network = false
}

# Enable essential bootstrap APIs
resource "google_project_service" "bootstrap" {
  for_each = toset(var.activate_apis)

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false

  timeouts {
    create = "10m"
    update = "10m"
  }
}
