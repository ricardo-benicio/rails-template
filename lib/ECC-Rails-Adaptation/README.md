# ECC Rails Adaptation

Extensão do [ECC](https://github.com/affaan-m/ECC) com skills, agentes e regras
específicos para ecossistemas **Ruby on Rails**.

---

## O que está incluído

| Arquivo | Tipo | Descrição |
|---|---|---|
| `skills/rails-patterns/SKILL.md` | Skill | Arquitetura Rails, ActiveRecord, service objects, Hotwire |
| `skills/rails-tdd/SKILL.md` | Skill | TDD com RSpec, FactoryBot, Capybara |
| `skills/rails-security/SKILL.md` | Skill | OWASP Top 10 para Rails, Pundit, Brakeman |
| `skills/rails-verification/SKILL.md` | Skill | CI/CD, N+1 detection, quality gates |
| `agents/ruby-reviewer.md` | Agent | Code review Ruby/Rails especializado |
| `agents/rails-build-resolver.md` | Agent | Diagnóstico de erros de build/bundle/migration |
| `rules/ruby/rails.md` | Rule | Diretrizes sempre-ativas para projetos Rails |
| `examples/rails-api-CLAUDE.md` | Exemplo | Template de CLAUDE.md para projeto Rails |

---

## Instalação no seu projeto (com ECC via plugin)

```bash
# 1. Clone ou baixe este repositório
git clone https://github.com/seu-usuario/ecc-rails.git

# 2. Copie as skills para o diretório do Claude Code
mkdir -p ~/.claude/skills/ecc
cp -r skills/rails-patterns ~/.claude/skills/ecc/
cp -r skills/rails-tdd      ~/.claude/skills/ecc/
cp -r skills/rails-security ~/.claude/skills/ecc/
cp -r skills/rails-verification ~/.claude/skills/ecc/

# 3. Copie os agentes
cp agents/ruby-reviewer.md          ~/.claude/agents/
cp agents/rails-build-resolver.md   ~/.claude/agents/

# 4. Copie as regras Ruby
mkdir -p ~/.claude/rules/ecc
cp -r rules/ruby ~/.claude/rules/ecc/

# 5. Copie o CLAUDE.md de exemplo para seu projeto e personalize
cp examples/rails-api-CLAUDE.md ~/meu-projeto-rails/CLAUDE.md
# Edite CLAUDE.md para refletir seu projeto específico
```

---

## Instalação manual (sem ECC base)

Se você não tem o ECC instalado e quer usar apenas as skills Rails diretamente
com Claude Code:

```bash
# No root do seu projeto Rails:
mkdir -p .claude/skills
cp -r path/to/ecc-rails/skills/rails-* .claude/skills/
cp -r path/to/ecc-rails/agents         .claude/
cp    path/to/ecc-rails/examples/rails-api-CLAUDE.md CLAUDE.md
```

---

## Uso

Com as skills instaladas, use no Claude Code:

```
# Revisar código
/ecc:code-review

# Planejar nova feature
/ecc:plan "Adicionar sistema de notificações com Action Cable"

# O agente ruby-reviewer é chamado automaticamente em code reviews
# O agente rails-build-resolver é sugerido quando houver erros de build

# Invocar skills diretamente (se suportado pelo seu harness):
# "Use the rails-tdd skill to help me write tests for UserService"
# "Apply rails-security skill to review this controller"
```

---

## Contribuindo

Para adicionar novas skills Rails (ex: `rails-hotwire`, `rails-graphql`,
`rails-cable`), siga a estrutura de qualquer `SKILL.md` existente:

```markdown
---
name: rails-[nome]
description: >
  Uma linha descrevendo quando usar esta skill.
tags: [ruby, rails, ...]
version: "1.0.0"
---

# Título

## Seção 1
...
```

Abra um PR com a nova skill e um teste de exemplo.
