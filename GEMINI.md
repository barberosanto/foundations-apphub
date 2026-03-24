# GEMINI.md: O Firmware do Projeto Foundations (App Hub & ADC)

## O Problema: A Repetição Exaustiva de Regras de Infra
Antes deste "Cockpit", trabalhar com IA neste repositório exigia que o engenheiro explicasse repetidamente a arquitetura: "Lembre-se que usamos o modelo de Management Project com ADC", "Não use os módulos de apphub standalone", "A autenticação é via ADC, não gcloud auth login", "Siga a hierarquia de pastas". Isso nos transformava em "capatazes de robô", microgerenciando cada arquivo e perdendo o foco estratégico 


## 🏛️ Contexto da Arquitetura (GCP Foundations)

Este projeto não é um Terraform comum. Ele provisiona uma **Fundação GCP** focada em **Application Design Center (ADC)** e **App Hub**.

**A Topologia Principal:**
- **Management Project:** Usamos um projeto de gestão central (`exemplosantodigital-appmgmt`).
- **Boundary Automático (ADC):** Não usamos `host projects` ou os módulos standalone de `apphub/` e `service_projects/`. O ADC é ativado no Console, transformando o projeto raiz em um *Management Project* e gerenciando o boundary automaticamente.
- **Hierarquia de Pastas:** Tudo fica debaixo de um folder raiz (Boundary) -> Ambientes (`cicd`, `dev`, `homologacao`, `producao`).
- **Spoke Projects:** Cada ambiente possui seus próprios projetos, criados via módulo `env_projects`.

---

## 🛑 Padrões (Standards) e Regras para o Agente

Para garantir a qualidade e manutenibilidade desta fundação, o agente (Gemini CLI) deve **sempre** seguir estas diretrizes:

### 1. Autenticação e Execução
- **Sempre assuma ADC:** O Terraform aqui não usa `gcloud auth login`. Ele depende estritamente do Application Default Credentials (`gcloud auth application-default login`). Ao sugerir comandos de troubleshooting de autenticação, foque no ADC e no `quota-project`.

### 2. Design e Módulos Terraform
- **Nunca reative módulos standalone de App Hub:** Os módulos `apphub` e `service_projects` no `main.tf` estão comentados de propósito (pois usamos o Management Project via console ADC). **Não sugira ativá-los** a menos que o usuário explicitamente deseje remover o ADC.
- **Módulos são a fonte da verdade:** Qualquer mudança estrutural deve ser feita nos submódulos em `foundations/modules/` (ex: `iam`, `env_projects`, `folders`). Evite inchar o `foundations/main.tf` com recursos isolados.
- **Ordem de Execução e Dependências:** Respeite o fluxo de passos do projeto (Bootstrap -> Folders -> APIs -> Env Projects -> IAM -> Design Center). Use `depends_on` explicitamente entre módulos quando orquestrar a criação.
- **Variáveis Estritas:** Ao criar novas variáveis em `variables.tf` ou nos módulos, sempre use `type` e `description`.

### 3. Mentalidade de Segurança e IAM (Staff Engineer Mindset)
- **Least Privilege:** O IAM é gerido no nível do projeto de gestão (App Hub/Design Center) e no nível das pastas (para acesso aos spokes). Não adicione roles desnecessárias de `roles/owner` ou `roles/editor` globais.
- **Sem Segredos no Código:** Credenciais ou service account keys jamais devem ser hardcoded ou criadas em modo texto.

### 4. Resolução de Problemas Comuns
- **Erro de Folders:** Se ocorrer `Permission 'resourcemanager.folders.create' denied`, lembre que `organizationAdmin` não inclui `folderCreator`.
- **Delay de IAM:** O GCP tem um propagation delay de até 7 minutos. Se um erro de "Permission denied" acontecer após criar uma role, sugira esperar e rodar o `apply` novamente em vez de refatorar o código.
- **Workarounds de CLI:** Sabemos que o Terraform ainda não cobre 100% da API de Spaces do Design Center, por isso usamos `terraform_data` + `local-exec` chamando `gcloud` no módulo `design_center`. Respeite este padrão.

> **Dica Pro (Para a IA e Desenvolvedores):** Pense como um arquiteto. Se o usuário pedir "Adicione uma nova API", você não apenas joga no `main.tf`, mas adiciona na lista do módulo `apis`. Mantenha a casa arrumada, o código declarativo legível e priorize soluções que facilitem a operação (High-Velocity Code).