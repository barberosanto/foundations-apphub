variable "project_id" {
  description = "Project ID where APIs will be enabled."
  type        = string
}

variable "apis" {
  description = "List of API service names to enable."
  type        = list(string)
}
