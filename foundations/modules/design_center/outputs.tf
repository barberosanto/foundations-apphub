output "space_ids" {
  description = "Map of space key → space ID created."
  value       = { for k, v in terraform_data.space : k => k }
}
