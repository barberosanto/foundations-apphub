# -----------------------------------------------------------------------------
# Organization & Billing (Bootstrap)
# -----------------------------------------------------------------------------
variable "org_id" {
  description = "GCP Organization numeric ID."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID to link to the management project. Format: XXXXXX-XXXXXX-XXXXXX."
  type        = string
}

variable "project_id" {
  description = "Management (hub) project ID — stores App Hub metadata and billing."
  type        = string
}

variable "project_name" {
  description = "Display name for the management project. Defaults to project_id if empty."
  type        = string
  default     = ""
}

variable "region" {
  description = "GCP region for App Hub applications."
  type        = string
  default     = "us-central1"
}

# -----------------------------------------------------------------------------
# Folder Hierarchy
# -----------------------------------------------------------------------------
variable "root_folder_name" {
  description = "Display name of the root (project) folder — becomes the App Hub boundary."
  type        = string
  default     = "projeto"
}

variable "environments" {
  description = <<-EOT
    Map of environment folders to create under the root folder.
    Key   = Terraform identifier (e.g. "dev", "hml", "prd").
    Value = display name shown in GCP Console.
  EOT
  type        = map(string)
  default = {
    "cicd"        = "cicd"
    "dev"         = "dev"
    "homologacao" = "homologacao"
    "producao"    = "producao"
  }
}

# -----------------------------------------------------------------------------
# IAM — App Hub Roles (project-level)
# -----------------------------------------------------------------------------
variable "app_hub_admins" {
  description = "List of IAM members to grant roles/apphub.admin."
  type        = list(string)
  default     = []
}

variable "app_hub_editors" {
  description = "List of IAM members to grant roles/apphub.editor."
  type        = list(string)
  default     = []
}

variable "app_hub_viewers" {
  description = "List of IAM members to grant roles/apphub.viewer."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# IAM — Design Center Roles (project-level)
# -----------------------------------------------------------------------------
variable "design_center_admins" {
  description = "List of IAM members to grant roles/designcenter.admin (create/manage templates & spaces)."
  type        = list(string)
  default     = []
}

variable "design_center_users" {
  description = "List of IAM members to grant roles/designcenter.user (use templates & deploy apps)."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Folder-level Access Groups
# -----------------------------------------------------------------------------
variable "folder_access_groups" {
  description = <<-EOT
    Map of access groups with folder-level IAM bindings.
    Key   = identifier (e.g. "dev-team", "devops-team").
    Value = object:
      member  : IAM identity (group:email, user:email, serviceAccount:email)
      role    : IAM role to grant on the folders
      folders : list of environment keys, OR ["all"] for root + all environments
  EOT
  type = map(object({
    member  = string
    role    = string
    folders = list(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Environment Spoke Projects
# -----------------------------------------------------------------------------
variable "env_projects" {
  description = <<-EOT
    Map of spoke projects to create inside environment folders.
    Key   = project identifier (e.g. "projeto-x-dev").
    Value = object:
      project_id    : globally unique GCP project ID
      display_name  : display name in console
      folder_key    : which environment folder (key from environments)
      activate_apis : optional list of APIs to enable on this project
  EOT
  type = map(object({
    project_id    = string
    display_name  = string
    folder_key    = string
    activate_apis = optional(list(string), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Hub-Spoke: Extra Service Projects (already existing)
# -----------------------------------------------------------------------------
variable "extra_service_projects" {
  description = <<-EOT
    Map of EXISTING spoke projects to attach (not created by Terraform).
    Key   = identifier. Value = object with project_id and number.
  EOT
  type = map(object({
    project_id = string
    number     = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# App Hub Applications
# -----------------------------------------------------------------------------
variable "applications" {
  description = <<-EOT
    Map of App Hub applications to create.
    Key   = application_id (e.g. "payments-app").
    Value = object with display_name, criticality, and environment.
      criticality  : MISSION_CRITICAL | HIGH | MEDIUM | LOW
      environment  : PRODUCTION | STAGING | TEST | DEVELOPMENT
  EOT
  type = map(object({
    display_name = string
    criticality  = optional(string, "MEDIUM")
    environment  = optional(string, "DEVELOPMENT")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Design Center Spaces
# -----------------------------------------------------------------------------
variable "design_center_spaces" {
  description = <<-EOT
    Map of Design Center spaces to create via gcloud CLI (local-exec).
    Key   = space_id (unique identifier, e.g. "platform-team").
    Value = object with display_name.
  EOT
  type = map(object({
    display_name = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# DevOps Service Account
# -----------------------------------------------------------------------------
variable "create_devops_sa" {
  description = "Whether to create the DevOps service account with granular deploy roles."
  type        = bool
  default     = true
}

variable "devops_sa_name" {
  description = "Account ID for the DevOps service account."
  type        = string
  default     = "sa-devops"
}

variable "devops_sa_display_name" {
  description = "Display name for the DevOps service account."
  type        = string
  default     = "DevOps Deploy SA"
}
