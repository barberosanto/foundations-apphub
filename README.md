# Google Cloud Foundations — App Hub + Application Design Center (ADC)

Este repositório contém o código Terraform e o tutorial passo a passo para provisionar uma fundação completa no Google Cloud Platform (GCP). O objetivo é criar uma estrutura robusta baseada em **Application Design Center (ADC)** e **App Hub**, incluindo projeto de gestão, hierarquia de pastas, ativação de APIs, configuração de IAM e provisionamento de projetos satélites (*Spokes*).

---

## 1. A Arquitetura do Projeto

Quando organizações crescem no GCP, elas precisam de uma forma padronizada de gerenciar projetos, permissões e Aplicações. O **App Hub** descobre e organiza recursos em "Aplicações" lógicas, e o **Application Design Center (ADC)** é a evolução visual e arquitetural dessa gestão.

Para suportar isso, este Terraform cria uma topologia "hub-and-spoke" focada no modelo de **Management Project**.

![Visão Geral da Arquitetura](docs/architecture.png)
*(Versões editáveis disponíveis em `docs/architecture.drawio` e `docs/architecture.svg`)*

### Topologia Criada:
```text
organizations/110137831008
├── exemplosantodigital-appmgmt          ← Management Project (ADC + App Hub)
└── 📁 exemplosantodigital/              ← Root folder (Boundary do ADC)
    ├── 📁 cicd/
    │   └── exemplosantodigital-x-cicd   ← Spoke project
    ├── 📁 dev/
    │   └── exemplosantodigital-x-dev
    ├── 📁 homologacao/
    │   └── exemplosantodigital-x-hml
    └── 📁 producao/
        └── exemplosantodigital-x-prd
```

---

## 2. Conceitos Fundamentais: Management Project vs. Host Project

O GCP diferencia dois tipos de projeto para o App Hub. **Este projeto utiliza exclusivamente o modelo Management Project (ADC).**

| Tipo | Descrição | Quem gerencia os Spokes |
|------|-----------|-------------------------|
| **Management Project** | O ADC é habilitado pelo console apontando para uma pasta raiz (*Boundary*). Todos os projetos dentro da pasta são descobertos automaticamente. | **Console (ADC)** |
| **Host Project (Legado)** | Exigia a criação manual de `service_project_attachments` via API/Terraform para cada projeto satélite. | **Terraform** |

> ⚠️ **Atenção:** Como usamos o modelo ADC, os módulos `apphub` e `service_projects` estão comentados no `main.tf`. O Terraform **não** cria os *attachments*, pois isso será feito automaticamente pelo Boundary do ADC após habilitado no Console.

---

## 3. Pré-Requisitos e Autenticação

### 1. Permissões na Organização
O usuário executando o Terraform precisa das seguintes *roles* na Organização:
- `roles/resourcemanager.organizationAdmin` (Admin geral)
- `roles/resourcemanager.folderCreator` (Criar pastas)
- `roles/resourcemanager.projectCreator` (Criar projetos)

### 2. Autenticação (ADC)
**O Terraform usa Application Default Credentials (ADC), NÃO apenas `gcloud auth login`.**

```bash
# 1. Login padrão (para comandos gcloud do módulo design_center)
gcloud auth login

# 2. Login ADC — ESSENCIAL para o Terraform
gcloud auth application-default login

# 3. Definir Quota-project (evita erros 403 em organizações com restrições)
gcloud auth application-default set-quota-project <SEU_PROJECT_ID>
```

---

## 4. Estrutura de Módulos e Ordem de Execução

O `foundations/main.tf` orquestra a execução em passos claros para manter as dependências corretas:

| Passo | Módulo | Descrição do que o Terraform faz |
|---|--------|-----------|
| **0** | `project` | (Bootstrap) Cria o projeto de gestão, vincula o billing e ativa APIs base. |
| **1** | `folders` | Cria a pasta raiz (*Boundary*) e as subpastas (ambientes). |
| **2** | `apis` | Ativa as 11+ APIs essenciais (App Hub, Design Center, Monitoring, etc.) no projeto de gestão. |
| **3** | `env_projects` | Cria os projetos *Spokes* dentro das pastas e habilita a API do App Hub neles. |
| **4** | *(Manual)* | **Pausa no Terraform:** Você deve ir ao Console GCP e habilitar o ADC. |
| **5** | `iam` | Aplica as *roles* de App Hub e Design Center e gerencia os acessos no nível das pastas. |
| **6** | `design_center`| Cria os *Spaces* do Design Center via `gcloud` local (workaround atual do Terraform). |

---

## 5. Como Executar (Passo a Passo)

### Passo 1: Configurar Variáveis
Copie o arquivo de exemplo e preencha com os dados da sua organização:
```bash
cd foundations
cp terraform.tfvars.example terraform.tfvars
```
Edite o `terraform.tfvars` preenchendo o `org_id`, `billing_account` e personalizando as aplicações e grupos de acesso (`folder_access_groups`).

### Passo 2: Inicializar e Aplicar
```bash
terraform init
terraform plan
terraform apply
```

### Passo 3: Habilitar o ADC no Console (Ação Manual)
Como a API do GCP ainda não suporta a ativação do *Boundary* via Terraform, você deve fazer isso uma única vez:
1. Abra o Console do Google Cloud.
2. Acesse o seu projeto de gestão (ex: `exemplosantodigital-appmgmt`).
3. Busque por **"App Management"** ou **"Design Center"**.
4. Clique em **Enable**. O GCP configurará o Boundary automaticamente na pasta raiz criada.

---

## 6. Troubleshooting Comum

- ❌ **`Permission 'resourcemanager.folders.create' denied`**
  **Causa:** A role `organizationAdmin` não inclui permissão para criar pastas.
  **Solução:** Conceda a role `roles/resourcemanager.folderCreator` ao seu usuário.

- ❌ **`Permission 'apphub.serviceProjectAttachments.attach' denied`**
  **Causa:** Demora na propagação de IAM.
  **Solução:** O módulo já concede a permissão correta (`roles/apphub.admin`), mas o GCP pode levar até 7 minutos para aplicar (*Propagation Delay*). Aguarde alguns minutos e rode `terraform apply` novamente.

- ❌ **`requested host project is a management project`**
  **Causa:** O Terraform está tentando rodar módulos legados de App Hub em um projeto ADC.
  **Solução:** Mantenha os módulos `apphub` e `service_projects` comentados no `main.tf`.

- ❌ **`User admin@... does not exist`**
  **Causa:** E-mail ou grupo Workspace inválido no `terraform.tfvars`.
  **Solução:** Certifique-que de que os grupos e usuários especificados no bloco IAM realmente existem no seu Google Workspace.

---

## App Hub Standalone (Modo Legado sem ADC)

Caso precise rodar a versão legada (sem a facilidade visual e o Boundary do Design Center):
1. Descomente os módulos `apphub` e `service_projects` no `foundations/main.tf`.
2. **NÃO** clique em "Enable" no Console para ativar o ADC.
3. O Terraform criará os *attachments* manualmente um por um.
