variable "billing_account" {
  description = "Billing account ID to link to spoke projects."
  type        = string
}

variable "environment_folder_ids" {
  description = "Map of environment key → folder resource name (folders/ID)."
  type        = map(string)
}

variable "projects" {
  description = <<-EOT
    Map of spoke projects to create inside environment folders.
    Key   = project identifier (e.g. "projeto-x-dev").
    Value = object:
      project_id   : globally unique GCP project ID
      display_name : display name in console
      folder_key   : which environment folder to place it in (key from environments)
      activate_apis: optional list of additional APIs to enable
  EOT
  type = map(object({
    project_id    = string
    display_name  = string
    folder_key    = string
    activate_apis = optional(list(string), [])
  }))
  default = {}
}

variable "hub_admins" {
  description = "List of members to grant roles/apphub.admin on spoke projects (required for attachments)."
  type        = list(string)
  default     = []
}
