# Google Cloud Foundations — App Hub + Application Design Center

Terraform para provisionar a **fundação de um ambiente GCP** com **Application Design Center (ADC)** — cria projeto de gestão, hierarquia de pastas, ativa APIs, configura IAM, spoke projects por ambiente e Spaces do Design Center.

## Arquitetura

```
organizations/110137831008
├── exemplosantodigital-appmgmt          ← Management Project (ADC + App Hub)
└── 📁 exemplosantodigital/              ← Root folder (boundary)
    ├── 📁 cicd/
    │   └── exemplosantodigital-x-cicd   ← Spoke project
    ├── 📁 dev/
    │   └── exemplosantodigital-x-dev
    ├── 📁 homologacao/
    │   └── exemplosantodigital-x-hml
    └── 📁 producao/
        └── exemplosantodigital-x-prd
```

> O diagrama editável está em [`docs/architecture.drawio`](docs/architecture.drawio).

## Conceitos Importantes

### Management Project vs Host Project

O GCP diferencia dois tipos de projeto para o App Hub:

| Tipo | Descrição | Quem gerencia spokes |
|------|-----------|---------------------|
| **Management Project** | Projeto com ADC habilitado pelo console. O boundary é criado automaticamente e gerencia os spokes via console. | Console (ADC) |
| **Host Project** | Projeto com `service_project_attachments` criados via API/Terraform. | Terraform |

> **⚠️ São mutuamente exclusivos.** Um projeto não pode ser management e host ao mesmo tempo. Este template usa o modelo **Management Project (ADC)**.

### O que o Terraform faz vs o Console

| Recurso | Gerenciado por |
|---------|---------------|
| Projeto de gestão, pastas, APIs, IAM, spoke projects, Design Center spaces | **Terraform** |
| Boundary, Applications, Service Project Attachments | **Console ADC** (Enable) |

## Pré-Requisitos

### 1. Roles na Organização

O user que roda o Terraform precisa destas roles na org:

| Role | Para quê |
|------|----------|
| `roles/resourcemanager.organizationAdmin` | Admin geral da org |
| `roles/resourcemanager.folderCreator` | Criar pastas (NÃO incluída no orgAdmin!) |
| `roles/resourcemanager.projectCreator` | Criar projetos |

```bash
ORG_ID=<sua_org_id>
USER=<seu_email>

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:$USER" --role="roles/resourcemanager.organizationAdmin"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:$USER" --role="roles/resourcemanager.folderCreator"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:$USER" --role="roles/resourcemanager.projectCreator"
```

### 2. Billing Account

Formato obrigatório: `XXXXXX-XXXXXX-XXXXXX` (6-6-6 caracteres alfanuméricos maiúsculos).

```bash
gcloud billing accounts list
```

### 3. Autenticação (ADC)

**O Terraform usa Application Default Credentials (ADC), NÃO `gcloud auth login`.**

```bash
# 1. Login padrão (para comandos gcloud do módulo design_center)
gcloud auth login

# 2. ADC — ESSENCIAL para o Terraform
gcloud auth application-default login

# 3. Quota-project (evita erros 403 em orgs com restrições)
gcloud auth application-default set-quota-project <PROJECT_ID>
```

## Estrutura de Módulos

```
foundations/
├── main.tf                          # Orquestra 6 módulos
├── variables.tf                     # Inputs parametrizados
├── outputs.tf                       # Outputs
├── versions.tf                      # Providers (google, google-beta, time)
├── terraform.tfvars                 # Valores do ambiente
└── modules/
    ├── project/                     # Bootstrap: criar projeto + billing
    ├── folders/                     # Passo 0: hierarquia de pastas
    ├── apis/                        # Passo 1: ativar 11 APIs
    ├── env_projects/                # Passo 2: spoke projects por ambiente
    ├── iam/                         # Passo 4: IAM (App Hub + Design Center + folders)
    ├── design_center/               # Passo 5: Design Center spaces (gcloud local-exec)
    ├── apphub/                      # (Comentado) App Hub standalone — sem ADC
    └── service_projects/            # (Comentado) Hub-spoke attachments — sem ADC
```

## Ordem de Execução

| # | Módulo | Recurso | Descrição |
|---|--------|---------|-----------|
| Bootstrap | `project` | `google_project` | Cria projeto de gestão + billing + 4 APIs essenciais |
| 0 | `folders` | `google_folder` | Folder root + sub-folders por ambiente |
| 1 | `apis` | `google_project_service` × 11 | Ativa APIs (App Hub, Design Center, Monitoring, etc.) |
| 2 | `env_projects` | `google_project` × N | Cria spoke projects nas pastas + habilita `apphub.googleapis.com` |
| 3 | _(ADC via Console)_ | — | Habilitar ADC: Console → App Management → **Enable** |
| 4 | `iam` | `google_project_iam_member` | Roles: apphub.admin, designcenter.admin, folder-level |
| 5 | `design_center` | `terraform_data` + `local-exec` | Spaces via `gcloud design-center spaces create` |

> **Passo 3 (ADC):** É feito manualmente no console uma única vez. O ADC cria automaticamente o boundary e gerencia os spoke projects. Não pode ser feito via Terraform porque o conceito de "management project" é exclusivo do ADC.

## Uso

```bash
# 1. Copiar e editar variáveis
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 2. Init & apply
terraform init
terraform plan
terraform apply -var-file=terraform.tfvars

# 3. Habilitar ADC no console (apenas uma vez)
# Console → projeto exemplosantodigital-appmgmt → App Management → Enable
```

## Inputs

| Variable | Type | Descrição |
|----------|------|-----------|
| `org_id` | `string` | ID numérico da organização |
| `billing_account` | `string` | ID do billing (formato `XXXXXX-XXXXXX-XXXXXX`) |
| `project_id` | `string` | ID do projeto de gestão |
| `project_name` | `string` | Display name do projeto |
| `region` | `string` | Região GCP (default: `us-east1`) |
| `root_folder_name` | `string` | Nome da folder raiz |
| `environments` | `map(string)` | Sub-folders a criar |
| `env_projects` | `map(object)` | Spoke projects por ambiente (project_id, display_name, folder_key, activate_apis) |
| `app_hub_admins` | `list(string)` | Members com `roles/apphub.admin` |
| `app_hub_editors` | `list(string)` | Members com `roles/apphub.editor` |
| `app_hub_viewers` | `list(string)` | Members com `roles/apphub.viewer` |
| `design_center_admins` | `list(string)` | Members com `roles/designcenter.admin` |
| `design_center_users` | `list(string)` | Members com `roles/designcenter.user` |
| `design_center_spaces` | `map(object)` | Spaces a criar no Design Center |
| `folder_access_groups` | `map(object)` | IAM groups no nível de folder |

## Outputs

| Output | Descrição |
|--------|-----------|
| `project_id` | ID do projeto de gestão |
| `project_number` | Número do projeto |
| `root_folder_id` | ID numérico da folder raiz |
| `root_folder_name` | Resource name (`folders/ID`) |
| `environment_folder_ids` | Map de ambiente → folder ID |
| `env_project_ids` | Map de spoke → project ID |
| `env_project_numbers` | Map de spoke → project number |
| `enabled_apis` | APIs ativadas no projeto de gestão |
| `iam_admins` | Members com apphub.admin |
| `iam_dc_admins` | Members com designcenter.admin |
| `design_center_spaces` | Spaces criados |

## Troubleshooting

### ❌ `Permission 'resourcemanager.folders.create' denied`

**Causa:** `roles/resourcemanager.organizationAdmin` **não** inclui permissão para criar pastas.

**Solução:**
```bash
gcloud organizations add-iam-policy-binding <ORG_ID> \
  --member="user:<EMAIL>" --role="roles/resourcemanager.folderCreator"
```

### ❌ `Error setting billing account ... invalid argument`

**Causa:** Formato incorreto do billing account.

**Solução:** Formato correto é `XXXXXX-XXXXXX-XXXXXX` (6-6-6). Verificar com `gcloud billing accounts list`.

### ❌ `name must be 4 to 30 characters with lowercase and uppercase letters...`

**Causa:** Display name com caracteres inválidos (acentos `ç`, `ã`, `é` ou barras `/`).

**Solução:** Usar nomes ASCII simples, até 30 caracteres (ex: `Projeto X - Producao`).

### ❌ `requested host project is a management project`

**Causa:** O projeto foi convertido para **management project** pelo ADC (console), e o Terraform tenta criar `service_project_attachments` que só funcionam em **host projects**. São mutuamente exclusivos.

**Solução:** Quando usar ADC, **não usar** os módulos `apphub` e `service_projects`. Eles estão comentados no `main.tf`. O ADC gerencia boundary e attachments automaticamente.

### ❌ `Permission 'apphub.serviceProjectAttachments.attach' denied`

**Causa (se usar App Hub standalone):** O user precisa de `roles/apphub.admin` em **cada spoke project**, não apenas no hub.

**Solução:** O módulo `env_projects` já concede `roles/apphub.admin` nos spokes via `hub_admins`. Pode levar até 7 min para propagar (IAM propagation delay). Rode `terraform apply` novamente.

### ❌ `service_project_attachment_id` com nome errado

**Causa:** O `service_project_attachment_id` deve ser o **project ID real** do GCP (ex: `exemplosantodigital-x-dev`), não um identificador customizado (ex: `projeto-x-dev`).

**Solução:** Já corrigido no módulo — usa `each.value.project_id`.

### ❌ `Invalid for_each argument ... will be known only after apply`

**Causa:** `for_each` requer chaves conhecidas em `plan`. Valores dinâmicos (IDs de folders) não podem ser chaves.

**Solução:** Já corrigido no módulo `iam` com variáveis estáticas (`environment_keys`, `has_root_folder`).

### ❌ `User admin@... does not exist`

**Causa:** Emails ou grupos inexistentes configurados nas variáveis de IAM.

**Solução:** Usar apenas emails válidos. Grupos devem ser criados no Google Workspace antes de serem referenciados.

### ⚠️ Terraform usa ADC, não `gcloud auth`

O Terraform **não** usa `gcloud auth login`. Ele usa **Application Default Credentials (ADC)**:

```bash
# Ver quota-project atual
cat ~/.config/gcloud/application_default_credentials.json | grep quota_project_id

# Reautenticar ADC
gcloud auth application-default login

# Apontar para o projeto correto
gcloud auth application-default set-quota-project <PROJECT_ID>
```

### ⚠️ IAM Propagation Delay

Após criar roles IAM, o GCP pode levar até **7 minutos** para propagar as permissões. Se um `terraform apply` falha com permission denied mas as IAM bindings já existem, espere e rode novamente.

## App Hub Standalone (sem ADC)

Se preferir **não usar o ADC** e gerenciar tudo via Terraform:

1. Descomente os módulos `apphub` e `service_projects` no `main.tf`
2. Descomente os outputs correspondentes no `outputs.tf`
3. **Não clique** "Enable" no console de App Management
4. Rode `terraform apply`

Isso cria `google_apphub_application` e `service_project_attachments` via Terraform, sem o boundary automático do ADC.
