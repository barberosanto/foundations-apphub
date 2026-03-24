terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0, < 7.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

# Provider configured at org level — project is created by Terraform.
# Individual modules pass project_id explicitly to each resource.
provider "google" {
  region = var.region
}

provider "google-beta" {
  region = var.region
}
