---
name: rails-discovery
description: >
  Analisa um projeto Ruby on Rails de ponta a ponta: mapeia o que existe,
  identifica lacunas de implementação, sugere features baseadas na arquitetura
  atual e gera um relatório priorizando o que pode ser construído a seguir.
  Combina codebase-onboarding + analyze-repo + workflow-discovery adaptados
  para o ecossistema Rails.
  Trigger: "explore this project", "what can be implemented", "analyze my Rails app",
  "onboard me", "what's missing in this project".
tags: [ruby, rails, discovery, analysis, onboarding, planning]
version: "1.0.0"
---

# Rails Discovery

Análise sistemática de um projeto Rails em 5 fases. Execute em ordem.
Ao final, produza o **Relatório de Descoberta** completo.

---

## Fase 1 — Fingerprinting (leitura rápida, sem abrir cada arquivo)

Rode estes comandos em paralelo para coletar sinais do projeto:

```bash
# Stack e versões
cat .ruby-version 2>/dev/null || ruby --version
cat Gemfile | grep -E "^gem |^  gem " | head -60
cat Gemfile.lock | grep "RUBY VERSION" -A2

# Estrutura de alto nível
find app -type d | sort
find config -name "*.rb" | sort
ls db/migrate | tail -20

# Rotas (mapa completo da API/UI)
bundle exec rails routes 2>/dev/null | head -100

# Schema atual
cat db/schema.rb 2>/dev/null | grep -E "create_table|t\.(string|integer|boolean|references|text|datetime)" | head -80

# Jobs cadastrados
find app/jobs -name "*.rb" | sort
find app/mailers -name "*.rb" | sort

# Testes existentes
find spec -name "*_spec.rb" | sort
bundle exec rspec --dry-run 2>/dev/null | tail -5

# Cobertura recente (se SimpleCov rodou antes)
cat coverage/.last_run.json 2>/dev/null

# CI/CD
ls .github/workflows 2>/dev/null
cat Procfile 2>/dev/null || cat Procfile.dev 2>/dev/null
```

**O que mapear nesta fase:**
- Versão do Rails e Ruby
- Gems principais instaladas (auth, jobs, search, payments, storage...)
- Quantos models, controllers, jobs, mailers existem
- Cobertura de testes atual
- Presença de CI/CD

---

## Fase 2 — Mapeamento de Domínio

Leia os arquivos centrais para entender o domínio da aplicação:

```bash
# Models (associações e validações definem o domínio)
find app/models -name "*.rb" ! -name "application_record.rb" | xargs grep -l "belongs_to\|has_many\|has_one" | head -15

# Controllers (superfície da API/UI)
find app/controllers -name "*.rb" ! -name "application_controller.rb" | sort

# Rotas em formato limpo
bundle exec rails routes 2>/dev/null | grep -v "^$\|rails\|active_storage\|action_mailbox\|turbo" | awk '{print $1, $2, $3}' | sort

# Background jobs (processos assíncronos = features em execução)
find app/jobs -name "*.rb" | xargs grep "def perform" 2>/dev/null -l

# Mailers (comunicação com usuários)
find app/mailers -name "*.rb" | xargs grep "def " 2>/dev/null | grep -v "#"
```

Para cada model encontrado, leia o arquivo e extraia:
- Associações (`belongs_to`, `has_many`, `has_one`, `has_many :through`)
- Validações (indicam regras de negócio)
- Callbacks (indicam efeitos colaterais)
- Scopes (indicam consultas frequentes)
- Enums (indicam estados/status do domínio)

**Construa mentalmente o grafo de entidades:**
```
User → [has_many] → Posts → [has_many] → Comments
                         → [has_many :through] → Tags
```

---

## Fase 3 — Auditoria de Implementação

Para cada área, verifique o que está completo, parcial ou ausente:

### 3a. Autenticação & Autorização
```bash
grep -r "devise\|rodauth\|has_secure_password" Gemfile
grep -r "authenticate_user!\|current_user" app/controllers --include="*.rb" -l
grep -r "pundit\|action_policy\|cancancan" Gemfile
find app/policies -name "*.rb" 2>/dev/null | wc -l
```

Verificar:
- [ ] Devise/Rodauth instalado e configurado?
- [ ] `authenticate_user!` em todos os controllers que precisam?
- [ ] Policies (Pundit) existem para cada model sensível?
- [ ] `verify_authorized` no ApplicationController?
- [ ] Roles/permissões implementadas?
- [ ] Password reset, email confirmation, lockable?

### 3b. API
```bash
grep -r "namespace :api" config/routes.rb
grep -r "jsonapi-serializer\|blueprinter\|active_model_serializers" Gemfile
grep -r "render json:" app/controllers --include="*.rb" | wc -l
grep -r "Serializer\|Blueprint" app --include="*.rb" | wc -l
```

Verificar:
- [ ] Versionamento de API (`/api/v1/`)?
- [ ] Serializers para todos os models expostos?
- [ ] Paginação implementada (pagy, kaminari, will_paginate)?
- [ ] Rate limiting (rack-attack)?
- [ ] Documentação de API (rswag, apipie)?
- [ ] CORS configurado para clients externos?

### 3c. Background Jobs
```bash
grep -r "sidekiq\|good_job\|delayed_job\|solid_queue" Gemfile
find app/jobs -name "*.rb" | sort
grep -r "perform_later\|perform_async" app --include="*.rb" | wc -l
cat config/sidekiq.yml 2>/dev/null
```

Verificar:
- [ ] Job backend configurado (Sidekiq/GoodJob)?
- [ ] Filas separadas por prioridade?
- [ ] `retry_on` e `discard_on` definidos nos jobs?
- [ ] Jobs com lógica pesada que deveria ser assíncrona mas não é?
- [ ] Scheduled jobs (cron) necessários mas ausentes?

### 3d. Storage & Uploads
```bash
grep -r "active_storage\|shrine\|carrierwave\|paperclip" Gemfile
bundle exec rails runner "puts ActiveStorage::Attachment.count" 2>/dev/null
cat config/storage.yml 2>/dev/null
```

Verificar:
- [ ] ActiveStorage configurado?
- [ ] Storage backend para produção (S3/GCS/Azure)?
- [ ] Validações de tipo e tamanho de arquivo?
- [ ] Variants/processamento de imagens (ImageProcessing)?

### 3e. Notificações & Mailers
```bash
find app/mailers -name "*.rb" | sort
grep -r "deliver_later\|deliver_now" app --include="*.rb" | wc -l
grep -r "ActionCable\|cable\|broadcast" app --include="*.rb" | wc -l
grep -r "noticed\|ahoy_matey" Gemfile
```

Verificar:
- [ ] Mailers existem para eventos importantes (boas-vindas, reset, notificações)?
- [ ] Emails sendo enviados com `deliver_later` (não `deliver_now`)?
- [ ] Action Cable para real-time?
- [ ] Sistema de notificações in-app (gem `noticed`)?

### 3f. Busca & Filtros
```bash
grep -r "pg_search\|ransack\|searchkick\|elasticsearch" Gemfile
grep -r "search\|filter\|query" app/models --include="*.rb" | grep "scope\|def " | head -20
```

Verificar:
- [ ] Busca full-text implementada?
- [ ] Filtros nas listagens?
- [ ] Indexes no banco para colunas de busca?

### 3g. Testes
```bash
find spec -name "*_spec.rb" | sed 's/spec\///' | sed 's/_spec.rb//' | awk -F/ '{print $1}' | sort | uniq -c | sort -rn
cat coverage/.last_run.json 2>/dev/null
bundle exec rspec --format progress --dry-run 2>/dev/null | tail -3
```

Verificar:
- [ ] Cobertura ≥ 80%?
- [ ] Specs para todos os services?
- [ ] Request specs para todos os endpoints?
- [ ] System specs para fluxos críticos?
- [ ] Jobs têm specs?

### 3h. Observabilidade
```bash
grep -r "sentry\|honeybadger\|rollbar\|bugsnag" Gemfile
grep -r "lograge\|semantic_logger" Gemfile
grep -r "skylight\|scout_apm\|datadog\|newrelic" Gemfile
grep -r "opentelemetry" Gemfile
```

Verificar:
- [ ] Error tracking (Sentry)?
- [ ] Structured logging (lograge)?
- [ ] APM / performance monitoring?
- [ ] Health endpoint `/health`?

### 3i. Segurança
```bash
bundle exec brakeman --no-pager -q 2>/dev/null | tail -20
grep -r "permit!" app/controllers --include="*.rb"
grep -r "html_safe\|raw " app/views 2>/dev/null | wc -l
grep -r "secure_headers\|content_security_policy" Gemfile config
bundle audit check 2>/dev/null | tail -10
```

Verificar:
- [ ] Sem `permit!` nos controllers?
- [ ] Brakeman sem HIGH/CRITICAL?
- [ ] Gems sem CVEs conhecidas?
- [ ] CSP headers configurados?
- [ ] Rate limiting ativo?

### 3j. Performance
```bash
grep -r "bullet" Gemfile
grep -r "rack-mini-profiler" Gemfile
grep -r "counter_cache\|includes\|preload\|eager_load" app/models --include="*.rb" | head -20
cat config/database.yml | grep -E "pool|timeout|prepared_statements"
```

Verificar:
- [ ] Bullet detectando N+1?
- [ ] `includes` nos controllers que listam associações?
- [ ] Caching implementado (Redis, fragment cache)?
- [ ] Connection pool ajustado para produção?

---

## Fase 4 — Identificação de Oportunidades

Com base nas fases 1–3, classifique cada lacuna encontrada em:

### 🔴 Crítico (deve ser feito antes de produção)
- Lacunas de segurança (autenticação ausente, autorização não aplicada)
- Gems com CVEs conhecidas
- Dados sem backup strategy

### 🟠 Alto Impacto (próximo sprint)
- Features core do domínio incompletas
- Testes com cobertura < 60%
- Jobs síncronos que deveriam ser assíncronos
- Mailers essenciais ausentes

### 🟡 Médio Impacto (próximos 2–3 sprints)
- Paginação ausente em listagens
- Busca não implementada
- Documentação de API ausente
- Serializers faltando

### 🟢 Melhoria contínua (backlog)
- Observabilidade aprimorada
- Cache de segundo nível
- Feature flags
- Internacionalização (i18n)

---

## Fase 5 — Geração do Relatório

Produza o **Relatório de Descoberta Rails** neste formato exato:

---

```markdown
# Relatório de Descoberta — [Nome do Projeto]
**Data:** [hoje]  **Rails:** [versão]  **Ruby:** [versão]

---

## Resumo Executivo
[2–3 parágrafos: o que o sistema faz, maturidade atual, maior risco identificado]

---

## Mapa do Domínio
[Grafo de entidades com associações]
[Tabela: Model | Campos principais | Associações | Status]

---

## O que está implementado ✅
[Lista do que funciona e está completo]

---

## O que está parcialmente implementado ⚠️
[Lista com o que falta em cada item]

---

## O que não existe e deveria 🔴
[Por prioridade: Crítico → Alto → Médio]

---

## Sugestões de Features por Área

### Autenticação & Segurança
- [ ] [feature] — [justificativa baseada no que foi encontrado]

### API & Integrações
- [ ] [feature] — [justificativa]

### Background Processing
- [ ] [feature] — [justificativa]

### Experiência do Usuário / Hotwire
- [ ] [feature] — [justificativa]

### Observabilidade & DevOps
- [ ] [feature] — [justificativa]

### Qualidade & Testes
- [ ] [feature] — [justificativa]

---

## Roadmap Sugerido

### Semana 1–2 (🔴 Crítico)
1. [item]
2. [item]

### Semana 3–6 (🟠 Alto impacto)
1. [item]
2. [item]

### Mês 2–3 (🟡 Médio impacto)
1. [item]

---

## Próximo Passo Recomendado
[Uma ação concreta e específica para começar agora]
Use: `/ecc:plan "[próximo passo recomendado]"`
```

---

## Uso

```
# Análise completa
"Use rails-discovery skill to analyze this project"

# Só o mapa de domínio
"Use rails-discovery Phase 1 and 2 to map the domain of this project"

# Só oportunidades de features
"Use rails-discovery Phase 3 and 4 to find what's missing in this project"

# Com foco específico
"Use rails-discovery focusing on security and background jobs"
```

## Integração com outros agentes

Após o relatório, o agente pode delegar automaticamente:

- `ruby-reviewer` → revisar os controllers/models mais críticos encontrados
- `rails-build-resolver` → se houver erros durante os comandos de diagnóstico
- `/ecc:plan` → para qualquer item do roadmap gerado
