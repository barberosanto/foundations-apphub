variable "org_id" {
  description = "GCP Organization numeric ID."
  type        = string
}

variable "project_id" {
  description = "Project ID for the management project."
  type        = string
}

variable "project_name" {
  description = "Display name for the management project."
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "Billing account ID to link. Format: XXXXXX-XXXXXX-XXXXXX."
  type        = string
}

variable "folder_id" {
  description = "Optional folder ID to place the project in. If empty, project is created under the org."
  type        = string
  default     = ""
}

variable "activate_apis" {
  description = "List of APIs to enable on the project (bootstrapping essentials)."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
  ]
}
