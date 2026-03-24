# =============================================================================
# Bootstrap — Criar Projeto de Gestão
# =============================================================================
# Em uma org zerada, o primeiro passo é criar o projeto que gerencia o App Hub.
# =============================================================================
module "project" {
  source = "./modules/project"

  org_id          = var.org_id
  project_id      = var.project_id
  project_name    = var.project_name
  billing_account = var.billing_account
}

# =============================================================================
# Passo 0 — Criar Hierarquia de Pastas GCP
# =============================================================================
#
#   organizations/ORG_ID
#   └── projeto          ← App Hub boundary (root folder)
#       ├── cicd
#       ├── dev
#       ├── homologacao
#       └── producao
#
# =============================================================================
module "folders" {
  source = "./modules/folders"

  parent           = "organizations/${var.org_id}"
  root_folder_name = var.root_folder_name
  environments     = var.environments
}

# =============================================================================
# Passo 1 — Ativar APIs
# =============================================================================
module "apis" {
  source = "./modules/apis"

  project_id = module.project.project_id
  apis = [
    "apphub.googleapis.com",              # App Hub API
    "designcenter.googleapis.com",        # Design Center API
    "storage.googleapis.com",             # Cloud Storage API
    "config.googleapis.com",              # Infrastructure Manager API
    "cloudbuild.googleapis.com",          # Cloud Build API
    "monitoring.googleapis.com",          # Cloud Monitoring API
    "logging.googleapis.com",             # Cloud Logging API
    "observability.googleapis.com",       # Observability API
    "cloudasset.googleapis.com",          # Cloud Asset API
    "servicehealth.googleapis.com",       # Service Health API
    "appoptimize.googleapis.com",         # App Optimize API
    "container.googleapis.com",           # GKE API
    "run.googleapis.com",                 # Cloud Run API
    "sqladmin.googleapis.com",            # Cloud SQL Admin API
    "compute.googleapis.com",             # Compute Engine API
    "servicenetworking.googleapis.com",   # Service Networking API
    "iam.googleapis.com",                 # IAM API
    "aiplatform.googleapis.com",          # Vertex AI API
    "cloudkms.googleapis.com",            # Cloud KMS API
    "developerconnect.googleapis.com",    # Developer Connect API
  ]

  depends_on = [module.project]
}

# =============================================================================
# Passo 2 — Criar Projetos nos Ambientes (Spokes)
# =============================================================================
module "env_projects" {
  source = "./modules/env_projects"

  billing_account        = var.billing_account
  environment_folder_ids = module.folders.environment_folders
  projects               = var.env_projects
  hub_admins             = var.app_hub_admins

  depends_on = [module.folders]
}

# =============================================================================
# Passo 3 — Boundary + Applications (gerenciado pelo ADC)
# =============================================================================
# NOTA: Quando o ADC (Application Design Center) é habilitado via console,
# o projeto se torna um "management project" com boundary automático.
# O boundary do ADC substitui:
#   - google_apphub_application (Passo 3)
#   - google_apphub_service_project_attachment (Passo 5)
#
# Para habilitar: Console → App Management → Enable
# O ADC cria automaticamente o boundary que inclui todos os projetos na folder.
#
# Se NÃO usar ADC, descomente os blocos abaixo para usar App Hub standalone:
# -----------------------------------------------------------------------------
# module "apphub" {
#   source = "./modules/apphub"
#
#   project_id   = module.project.project_id
#   region       = var.region
#   folder_id    = module.folders.root_folder_id
#   applications = var.applications
#
#   depends_on = [module.apis, module.folders]
# }
#
# resource "time_sleep" "wait_for_iam" {
#   depends_on      = [module.env_projects]
#   create_duration = "90s"
# }
#
# module "service_projects" {
#   source = "./modules/service_projects"
#
#   project_id = module.project.project_id
#   service_projects = merge(
#     module.env_projects.service_project_map,
#     var.extra_service_projects,
#   )
#
#   depends_on = [module.apis, module.env_projects, time_sleep.wait_for_iam]
# }
# -----------------------------------------------------------------------------

# =============================================================================
# Passo 4 — Conceder Acesso (IAM)
# =============================================================================
module "iam" {
  source = "./modules/iam"

  project_id     = module.project.project_id
  project_number = module.project.project_number
  admins         = var.app_hub_admins
  editors    = var.app_hub_editors
  viewers    = var.app_hub_viewers

  # Design Center roles
  design_center_admins = var.design_center_admins
  design_center_users  = var.design_center_users

  # Folder-level access groups
  has_root_folder        = true
  root_folder_id         = module.folders.root_folder_name
  environment_folder_ids = module.folders.environment_folders
  environment_keys       = keys(var.environments)
  folder_access_groups   = var.folder_access_groups

  # DevOps service account
  create_devops_sa       = var.create_devops_sa
  devops_sa_name         = var.devops_sa_name
  devops_sa_display_name = var.devops_sa_display_name

  depends_on = [module.project, module.folders]
}

# =============================================================================
# Passo 6 — Criar Spaces no Design Center (via gcloud CLI)
# =============================================================================
# O provider do Terraform ainda não possui recurso nativo para Spaces.
# Este módulo usa terraform_data + local-exec para chamar gcloud.
# =============================================================================
module "design_center" {
  source = "./modules/design_center"

  project_id = module.project.project_id
  location   = var.region
  spaces     = var.design_center_spaces

  depends_on = [module.apis, module.iam]
}

