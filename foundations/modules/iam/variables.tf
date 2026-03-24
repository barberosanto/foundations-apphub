variable "project_id" {
  description = "Project ID for project-level IAM bindings."
  type        = string
}

variable "project_number" {
  description = "Project number for constructing service agent emails."
  type        = string
}

# -----------------------------------------------------------------------------
# Project-level App Hub Roles
# -----------------------------------------------------------------------------
variable "admins" {
  description = "List of IAM members to grant roles/apphub.admin."
  type        = list(string)
  default     = []
}

variable "editors" {
  description = "List of IAM members to grant roles/apphub.editor."
  type        = list(string)
  default     = []
}

variable "viewers" {
  description = "List of IAM members to grant roles/apphub.viewer."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Project-level Design Center Roles
# -----------------------------------------------------------------------------
variable "design_center_admins" {
  description = "List of IAM members to grant roles/designcenter.admin."
  type        = list(string)
  default     = []
}

variable "design_center_users" {
  description = "List of IAM members to grant roles/designcenter.user."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Folder-level Access Groups
# -----------------------------------------------------------------------------
variable "root_folder_id" {
  description = "Resource name of the root folder (folders/ID) for 'all' scope."
  type        = string
  default     = ""
}

variable "has_root_folder" {
  description = "Whether a root folder exists (static bool, known at plan-time)."
  type        = bool
  default     = true
}

variable "environment_folder_ids" {
  description = "Map of environment key → folder resource name (folders/ID)."
  type        = map(string)
  default     = {}
}

variable "environment_keys" {
  description = "Static list of environment keys (known at plan-time) for 'all' expansion."
  type        = list(string)
  default     = []
}

variable "folder_access_groups" {
  description = <<-EOT
    Map of access groups with folder-level IAM bindings.
    Key   = identifier (e.g. "dev-team", "devops-team").
    Value = object:
      member  : IAM identity (group:email, user:email, serviceAccount:email)
      role    : IAM role to grant on the folders (e.g. roles/editor, roles/viewer)
      folders : list of environment keys to grant access to, OR ["all"] for all folders + root
  EOT
  type = map(object({
    member  = string
    role    = string
    folders = list(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# DevOps Service Account
# -----------------------------------------------------------------------------
variable "create_devops_sa" {
  description = "Whether to create the DevOps service account and its role bindings."
  type        = bool
  default     = true
}

variable "devops_sa_name" {
  description = "Account ID for the DevOps service account (before @project.iam...)."
  type        = string
  default     = "sa-devops"
}

variable "devops_sa_display_name" {
  description = "Display name for the DevOps service account."
  type        = string
  default     = "DevOps Deploy SA"
}
