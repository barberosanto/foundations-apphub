# =============================================================================
# Project-level App Hub Roles
# =============================================================================
resource "google_project_iam_member" "admin" {
  for_each = toset(var.admins)

  project = var.project_id
  role    = "roles/apphub.admin"
  member  = each.value
}

resource "google_project_iam_member" "editor" {
  for_each = toset(var.editors)

  project = var.project_id
  role    = "roles/apphub.editor"
  member  = each.value
}

resource "google_project_iam_member" "viewer" {
  for_each = toset(var.viewers)

  project = var.project_id
  role    = "roles/apphub.viewer"
  member  = each.value
}

# =============================================================================
# Project-level Design Center Roles
# =============================================================================
resource "google_project_iam_member" "dc_admin" {
  for_each = toset(var.design_center_admins)

  project = var.project_id
  role    = "roles/designcenter.admin"
  member  = each.value
}

resource "google_project_iam_member" "dc_user" {
  for_each = toset(var.design_center_users)

  project = var.project_id
  role    = "roles/designcenter.user"
  member  = each.value
}

# =============================================================================
# Folder-level Access Groups
# =============================================================================

# Resolve "all" keyword → expand to root + all environment folder keys
locals {
  # Static list of all folder keys (known at plan-time)
  all_static_keys = concat(
    var.has_root_folder ? ["_root"] : [],
    var.environment_keys,
  )

  # Folder ID lookup map (values are apply-time, but only used in resource attrs)
  all_folder_ids = merge(
    var.has_root_folder ? { "_root" = var.root_folder_id } : {},
    var.environment_folder_ids,
  )

  # Flatten: one entry per (group × folder) combination
  # Keys are fully static (known at plan-time)
  folder_bindings = flatten([
    for group_key, group in var.folder_access_groups : [
      for folder_key in(
        contains(group.folders, "all")
        ? local.all_static_keys
        : group.folders
        ) : {
        key        = "${group_key}--${folder_key}"
        member     = group.member
        role       = group.role
        folder_key = folder_key
      }
    ]
  ])

  # Convert to map for for_each — keys are static strings
  folder_bindings_map = {
    for b in local.folder_bindings : b.key => b
  }
}

resource "google_folder_iam_member" "access" {
  for_each = local.folder_bindings_map

  folder = local.all_folder_ids[each.value.folder_key]
  role   = each.value.role
  member = each.value.member
}

# =============================================================================
# DevOps Service Account — Granular Roles
# =============================================================================
resource "google_service_account" "devops" {
  count = var.create_devops_sa ? 1 : 0

  project      = var.project_id
  account_id   = var.devops_sa_name
  display_name = var.devops_sa_display_name
  description  = "Service account for CI/CD deployments (GKE, Cloud Run, Cloud SQL, Compute Engine, Networking)."
}

locals {
  devops_roles = var.create_devops_sa ? toset([
    # --- GKE ---
    "roles/container.developer",        # Deploy workloads (pods, deployments, services)
    "roles/container.clusterViewer",    # View existing clusters (read-only cluster access)

    # --- Cloud Run ---
    "roles/run.admin",                  # Full Cloud Run management (deploy, VPC config)

    # --- Cloud SQL ---
    "roles/cloudsql.admin",             # Full Cloud SQL access (create instances, databases, users)
    "roles/cloudsql.client",            # Connect via Cloud SQL Proxy / IAM auth

    # --- Compute Engine + Networking ---
    "roles/compute.admin",              # Full compute access (VMs, disks, LBs, firewalls, VPCs)

    # --- Cloud KMS ---
    "roles/cloudkms.cryptoKeyEncrypterDecrypter", # Encrypt/decrypt with KMS keys

    # --- Storage (container images / artifacts) ---
    "roles/storage.admin",              # Push/pull container images (GCR / Artifact Registry)

    # --- IAM (act as other SAs for deploy) ---
    "roles/iam.serviceAccountUser",     # Impersonate SAs (required for deploy targets)
    "roles/iam.serviceAccountAdmin",    # Create/manage service accounts in projects

    # --- Observability ---
    "roles/logging.logWriter",          # Write application/runtime logs
    "roles/monitoring.metricWriter",    # Write custom and runtime metrics

    # --- Vertex AI ---
    "roles/aiplatform.admin",           # Full access to Vertex AI (models, endpoints, pipelines)

    # --- Secret Manager ---
    "roles/secretmanager.admin",        # Create/manage/access secrets

    # --- Pub/Sub ---
    "roles/pubsub.admin",              # Create/manage topics and subscriptions

    # --- Cloud Build ---
    "roles/cloudbuild.builds.editor",  # Trigger and manage builds

    # --- Service Networking ---
    "roles/servicenetworking.networksAdmin", # Manage VPC peering (Cloud SQL, etc.)

    # --- App Engine ---
    "roles/appengine.appAdmin",        # Deploy and manage App Engine apps

    # --- IAP ---
    "roles/iap.admin",                 # Manage Identity-Aware Proxy settings

    # --- Resource Manager ---
    "roles/resourcemanager.projectIamAdmin", # Manage project-level IAM policies

    # --- Infrastructure Manager (used by ADC) ---
    "roles/config.admin",              # Manage Infrastructure Manager deployments

    # --- Service Usage (required by ADC to list/enable APIs) ---
    "roles/serviceusage.serviceUsageConsumer", # Use services in projects

    # --- App Hub (required by ADC for service discovery) ---
    "roles/apphub.admin",              # List/register discovered services
  ]) : toset([])
}

resource "google_folder_iam_member" "devops_roles" {
  for_each = local.devops_roles

  folder = var.root_folder_id
  role   = each.value
  member = "serviceAccount:${google_service_account.devops[0].email}"
}

# =============================================================================
# DevOps SA — Management Project bindings
# The management project sits OUTSIDE the folder hierarchy, so folder-level
# bindings don't cascade to it. ADC stores artifacts in buckets here.
# =============================================================================
locals {
  devops_mgmt_project_roles = var.create_devops_sa ? toset([
    "roles/storage.admin",              # Access ADC buckets (adc-*) for deployments
    "roles/cloudbuild.builds.editor",   # Cloud Build runs in management project
    "roles/logging.logWriter",          # Write build/deploy logs
    "roles/iam.serviceAccountUser",     # Impersonate SAs in management project
    "roles/config.admin",              # Infrastructure Manager (ADC deploys)
    "roles/apphub.admin",              # App Hub service discovery
  ]) : toset([])
}

resource "google_project_iam_member" "devops_mgmt_roles" {
  for_each = local.devops_mgmt_project_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.devops[0].email}"
}

# =============================================================================
# Design Center Service Agent → can impersonate DevOps SA
# =============================================================================
resource "google_service_account_iam_member" "design_center_uses_devops" {
  count = var.create_devops_sa ? 1 : 0

  service_account_id = google_service_account.devops[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${var.project_number}@gcp-sa-designcenter.iam.gserviceaccount.com"
}
