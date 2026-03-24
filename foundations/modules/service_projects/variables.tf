variable "project_id" {
  description = "Hub (management) project ID for App Hub attachments."
  type        = string
}

variable "service_projects" {
  description = <<-EOT
    Map of spoke projects to attach to the hub.
    Key   = identifier (e.g. "dev", "staging", "prod").
    Value = object with project_id and number.
  EOT
  type = map(object({
    project_id = string
    number     = string
  }))
  default = {}
}
