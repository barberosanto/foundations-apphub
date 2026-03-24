# =============================================================================
# Design Center — Space creation via gcloud CLI
# =============================================================================
# The google Terraform provider does not yet have a native resource for
# Design Center Spaces.  We use terraform_data + local-exec to call gcloud.
# =============================================================================

resource "terraform_data" "space" {
  for_each = var.spaces

  # Re-create only when these inputs change
  input = {
    space_id     = each.key
    project_id   = var.project_id
    location     = var.location
    display_name = each.value.display_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      gcloud design-center spaces create ${each.key} \
        --project=${var.project_id} \
        --location=${var.location} \
        --display-name="${each.value.display_name}" \
        --quiet \
      || echo "Space '${each.key}' may already exist — skipping."
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      gcloud design-center spaces delete ${self.input.space_id} \
        --project=${self.input.project_id} \
        --location=${self.input.location} \
        --quiet \
      || echo "Space '${self.input.space_id}' may already be deleted — skipping."
    EOT
  }
}
