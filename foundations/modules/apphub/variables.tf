variable "project_id" {
  description = "Management project ID for App Hub."
  type        = string
}

variable "region" {
  description = "GCP region for App Hub applications."
  type        = string
}

variable "folder_id" {
  description = "Numeric ID of the app-enabled GCP folder."
  type        = string
}

variable "applications" {
  description = <<-EOT
    Map of App Hub applications to create.
    Key   = application_id (e.g. "payments-app").
    Value = object with display_name, criticality, and environment.
  EOT
  type = map(object({
    display_name = string
    criticality  = optional(string, "MEDIUM")
    environment  = optional(string, "DEVELOPMENT")
  }))
  default = {}
}
