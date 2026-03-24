# =============================================================================
# App-Enabled Folder Scope
# =============================================================================
data "google_folder" "scope" {
  folder = "folders/${var.folder_id}"
}

# =============================================================================
# App Hub Applications
# =============================================================================
resource "google_apphub_application" "this" {
  for_each = var.applications

  project        = var.project_id
  application_id = each.key
  location       = var.region
  display_name   = each.value.display_name

  scope {
    type = "REGIONAL"
  }

  attributes {
    criticality {
      type = each.value.criticality
    }
    environment {
      type = each.value.environment
    }
  }
}
