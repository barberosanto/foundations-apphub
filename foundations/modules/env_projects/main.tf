# =============================================================================
# Spoke Projects — one per environment
# =============================================================================
# Creates GCP projects inside the environment folders.
#
#   projeto/
#   ├── cicd/
#   │   └── projeto-x-cicd (project)
#   ├── dev/
#   │   └── projeto-x-dev (project)
#   ├── homologacao/
#   │   └── projeto-x-hml (project)
#   └── producao/
#       └── projeto-x-prd (project)
#
# =============================================================================

resource "google_project" "this" {
  for_each = var.projects

  name            = each.value.display_name
  project_id      = each.value.project_id
  folder_id       = var.environment_folder_ids[each.value.folder_key]
  billing_account = var.billing_account

  auto_create_network = false
}

# Enable APIs on each spoke project
# apphub.googleapis.com is always required for service project attachments
locals {
  # APIs that MUST be enabled on every spoke for App Hub attachments
  required_spoke_apis = ["apphub.googleapis.com"]

  project_apis = flatten([
    for proj_key, proj in var.projects : [
      for api in distinct(concat(local.required_spoke_apis, proj.activate_apis)) : {
        key        = "${proj_key}--${api}"
        project_id = proj.project_id
        api        = api
      }
    ]
  ])

  project_apis_map = {
    for item in local.project_apis : item.key => item
  }
}

resource "google_project_service" "spoke_apis" {
  for_each = local.project_apis_map

  project            = google_project.this[split("--", each.key)[0]].project_id
  service            = each.value.api
  disable_on_destroy = false

  depends_on = [google_project.this]
}

# =============================================================================
# Default VPC Network — created automatically for every spoke project
# =============================================================================
# auto_create_network is false so Terraform manages the network explicitly.
# Cloud Run, Cloud SQL, and other services expect a "default" network.
resource "google_compute_network" "default" {
  for_each = var.projects

  name                    = "default"
  project                 = google_project.this[each.key].project_id
  auto_create_subnetworks = true   # auto-mode: subnets in every region
  routing_mode            = "REGIONAL"

  depends_on = [
    google_project_service.spoke_apis   # compute.googleapis.com must be enabled first
  ]
}

# Grant apphub.admin on spoke projects so attachments can be created
locals {
  spoke_admin_bindings = flatten([
    for proj_key, proj in var.projects : [
      for member in var.hub_admins : {
        key        = "${proj_key}--${member}"
        project_id = proj.project_id
        member     = member
      }
    ]
  ])

  spoke_admin_map = {
    for item in local.spoke_admin_bindings : item.key => item
  }
}

resource "google_project_iam_member" "spoke_apphub_admin" {
  for_each = local.spoke_admin_map

  project = each.value.project_id
  role    = "roles/apphub.admin"
  member  = each.value.member

  depends_on = [google_project.this, google_project_service.spoke_apis]
}
