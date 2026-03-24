variable "parent" {
  description = "Parent resource where the top-level folder is created. Format: 'organizations/ORG_ID' or 'folders/FOLDER_ID'."
  type        = string
}

variable "root_folder_name" {
  description = "Display name of the root (project) folder that acts as the App Hub boundary."
  type        = string
  default     = "projeto"
}

variable "environments" {
  description = <<-EOT
    Map of environment folders to create under the root folder.
    Key   = identifier used in Terraform (e.g. "dev", "hml", "prd").
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
