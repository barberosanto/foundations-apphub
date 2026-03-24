# =============================================================================
# GCP Folder Hierarchy
# =============================================================================
#
#   parent (org or folder)
#   └── root_folder (projeto)  ← App Hub boundary
#       ├── cicd
#       ├── dev
#       ├── homologacao
#       └── producao
#
# =============================================================================

# --- Root folder (app-enabled boundary) ---
resource "google_folder" "root" {
  display_name = var.root_folder_name
  parent       = var.parent
}

# --- Environment sub-folders ---
resource "google_folder" "environments" {
  for_each = var.environments

  display_name = each.value
  parent       = google_folder.root.name
}
