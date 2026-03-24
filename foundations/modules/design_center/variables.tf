variable "project_id" {
  description = "Management project ID where Design Center is enabled."
  type        = string
}

variable "location" {
  description = "GCP region for the Design Center space."
  type        = string
}

variable "spaces" {
  description = <<-EOT
    Map of Design Center spaces to create.
    Key   = space_id (unique identifier).
    Value = object with display_name.
  EOT
  type = map(object({
    display_name = string
  }))
  default = {}
}
