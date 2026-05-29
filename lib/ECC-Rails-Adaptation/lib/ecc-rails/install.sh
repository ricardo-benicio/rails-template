#!/usr/bin/env bash
# =============================================================================
# ECC Rails Adaptation — Installer
# Instala skills, agentes e regras Rails no Claude Code
# Uso: ./install.sh [--project] [--global] [--uninstall] [--help]
# =============================================================================

set -euo pipefail

# --- Cores ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# --- Diretório onde este script está localizado ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Flags ---
MODE="global"         # global | project
UNINSTALL=false
DRY_RUN=false
SKIP_CLAUDE_MD=false

# --- Funções de log ---
info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERRO]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}${BLUE}=== $* ===${NC}\n"; }

# --- Ajuda ---
usage() {
  cat <<EOF
${BOLD}ECC Rails Adaptation — Installer${NC}

Uso:
  ./install.sh                  Instala globalmente em ~/.claude/
  ./install.sh --project        Instala no projeto atual (.claude/)
  ./install.sh --dry-run        Mostra o que seria feito sem executar
  ./install.sh --uninstall      Remove os arquivos instalados
  ./install.sh --skip-claude-md Não cria/sobrescreve o CLAUDE.md
  ./install.sh --help           Mostra esta ajuda

Exemplos:
  ./install.sh                          # instala global
  ./install.sh --project                # instala só neste projeto Rails
  ./install.sh --project --dry-run      # preview sem alterar nada
  ./install.sh --uninstall              # remove instalação global
EOF
  exit 0
}

# --- Parse args ---
for arg in "$@"; do
  case $arg in
    --project)       MODE="project" ;;
    --global)        MODE="global" ;;
    --uninstall)     UNINSTALL=true ;;
    --dry-run)       DRY_RUN=true ;;
    --skip-claude-md) SKIP_CLAUDE_MD=true ;;
    --help|-h)       usage ;;
    *) warn "Argumento desconhecido: $arg (ignorado)" ;;
  esac
done

# --- Resolve destino ---
if [[ "$MODE" == "global" ]]; then
  CLAUDE_DIR="$HOME/.claude"
  CLAUDE_MD_TARGET=""   # não cria CLAUDE.md globalmente
else
  CLAUDE_DIR="$(pwd)/.claude"
  CLAUDE_MD_TARGET="$(pwd)/CLAUDE.md"
fi

SKILLS_DIR="$CLAUDE_DIR/skills/ecc"
AGENTS_DIR="$CLAUDE_DIR/agents"
RULES_DIR="$CLAUDE_DIR/rules/ecc/ruby"

# --- Verificações ---
check_prerequisites() {
  header "Verificando pré-requisitos"

  # Claude Code
  if command -v claude &>/dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "desconhecido")
    success "Claude Code encontrado: $CLAUDE_VERSION"
  else
    warn "Claude Code não encontrado. Instale com: npm install -g @anthropic/claude-code"
  fi

  # Modo projeto: verificar se é um projeto Rails
  if [[ "$MODE" == "project" ]]; then
    if [[ ! -f "Gemfile" ]]; then
      error "Gemfile não encontrado. Execute este script na raiz do seu projeto Rails."
      exit 1
    fi
    if grep -q "rails" Gemfile 2>/dev/null; then
      success "Projeto Rails detectado em $(pwd)"
    else
      warn "Gemfile encontrado mas 'rails' não detectado. Continuando assim mesmo..."
    fi
  fi

  # Verificar se os arquivos fonte existem
  if [[ ! -d "$SCRIPT_DIR/skills" ]]; then
    error "Pasta 'skills/' não encontrada em $SCRIPT_DIR"
    error "Certifique-se de extrair o ZIP completo antes de rodar este script."
    exit 1
  fi

  success "Diretório de origem: $SCRIPT_DIR"
  success "Diretório destino:   $CLAUDE_DIR"
}

# --- Copia um arquivo/pasta com log ---
do_copy() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] Copiaria: $label → $dest"
    return
  fi

  if [[ -d "$src" ]]; then
    cp -r "$src" "$dest/"
  else
    cp "$src" "$dest/"
  fi
  success "$label"
}

# --- Remove com log ---
do_remove() {
  local target="$1"
  local label="$2"

  if [[ ! -e "$target" ]]; then
    info "Não encontrado (ok): $label"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] Removeria: $target"
    return
  fi

  rm -rf "$target"
  success "Removido: $label"
}

# --- Instalar skills ---
install_skills() {
  header "Instalando Skills Rails"

  [[ "$DRY_RUN" == false ]] && mkdir -p "$SKILLS_DIR"

  local skills=(
    "rails-patterns"
    "rails-tdd"
    "rails-security"
    "rails-verification"
    "rails-discovery"
  )

  for skill in "${skills[@]}"; do
    local src="$SCRIPT_DIR/skills/$skill"
    if [[ -d "$src" ]]; then
      do_copy "$src" "$SKILLS_DIR" "skill: $skill"
    else
      warn "Skill não encontrada: $skill (pulando)"
    fi
  done
}

# --- Instalar agentes ---
install_agents() {
  header "Instalando Agentes Rails"

  [[ "$DRY_RUN" == false ]] && mkdir -p "$AGENTS_DIR"

  local agents=(
    "ruby-reviewer.md"
    "rails-build-resolver.md"
    "rails-discovery-agent.md"
  )

  for agent in "${agents[@]}"; do
    local src="$SCRIPT_DIR/agents/$agent"
    if [[ -f "$src" ]]; then
      do_copy "$src" "$AGENTS_DIR" "agent: $agent"
    else
      warn "Agente não encontrado: $agent (pulando)"
    fi
  done
}

# --- Instalar rules ---
install_rules() {
  header "Instalando Rules Ruby/Rails"

  [[ "$DRY_RUN" == false ]] && mkdir -p "$RULES_DIR"

  local src="$SCRIPT_DIR/rules/ruby/rails.md"
  if [[ -f "$src" ]]; then
    do_copy "$src" "$RULES_DIR" "rule: rails.md"
  else
    warn "Rule não encontrada: rules/ruby/rails.md (pulando)"
  fi
}

# --- Criar CLAUDE.md no projeto ---
install_claude_md() {
  [[ "$MODE" != "project" ]] && return
  [[ "$SKIP_CLAUDE_MD" == true ]] && return

  header "Configurando CLAUDE.md"

  local template="$SCRIPT_DIR/examples/rails-api-CLAUDE.md"

  if [[ ! -f "$template" ]]; then
    warn "Template CLAUDE.md não encontrado — pulando"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] Criaria CLAUDE.md em $(pwd)/"
    return
  fi

  if [[ -f "$CLAUDE_MD_TARGET" ]]; then
    warn "CLAUDE.md já existe. Criando CLAUDE.md.rails-template (não sobrescreve)"
    cp "$template" "${CLAUDE_MD_TARGET}.rails-template"
    success "Template salvo em: CLAUDE.md.rails-template"
    echo ""
    warn "Compare com seu CLAUDE.md existente e mescle manualmente o que precisar."
  else
    cp "$template" "$CLAUDE_MD_TARGET"
    success "CLAUDE.md criado em $(pwd)/"
    echo ""
    warn "IMPORTANTE: Edite o CLAUDE.md para refletir o seu projeto:"
    warn "  - Rails/Ruby version"
    warn "  - Gems que você usa (Devise? Pundit? Sidekiq?)"
    warn "  - Modelos principais"
    warn "  - Variáveis de ambiente"
  fi
}

# --- Desinstalar ---
uninstall() {
  header "Desinstalando ECC Rails"

  do_remove "$SKILLS_DIR/rails-patterns"    "skill: rails-patterns"
  do_remove "$SKILLS_DIR/rails-tdd"         "skill: rails-tdd"
  do_remove "$SKILLS_DIR/rails-security"    "skill: rails-security"
  do_remove "$SKILLS_DIR/rails-verification" "skill: rails-verification"

  do_remove "$AGENTS_DIR/ruby-reviewer.md"            "agent: ruby-reviewer"
  do_remove "$AGENTS_DIR/rails-build-resolver.md"     "agent: rails-build-resolver"
  do_remove "$AGENTS_DIR/rails-discovery-agent.md"    "agent: rails-discovery-agent"

  do_remove "$RULES_DIR/rails.md" "rule: rails.md"

  if [[ "$MODE" == "project" && -f "${CLAUDE_MD_TARGET}.rails-template" ]]; then
    do_remove "${CLAUDE_MD_TARGET}.rails-template" "CLAUDE.md.rails-template"
  fi

  [[ "$DRY_RUN" == false ]] && success "Desinstalação concluída."
}

# --- Resumo final ---
show_summary() {
  header "Resumo"

  if [[ "$DRY_RUN" == true ]]; then
    warn "Modo dry-run — nenhum arquivo foi alterado."
    echo ""
  fi

  echo -e "  ${BOLD}Skills instaladas em:${NC}  $SKILLS_DIR"
  echo -e "  ${BOLD}Agentes instalados em:${NC} $AGENTS_DIR"
  echo -e "  ${BOLD}Rules instaladas em:${NC}   $RULES_DIR"

  if [[ "$MODE" == "project" ]]; then
    echo -e "  ${BOLD}CLAUDE.md:${NC}             $(pwd)/CLAUDE.md"
  fi

  echo ""
  echo -e "${BOLD}Próximos passos:${NC}"

  if [[ "$MODE" == "project" ]]; then
    echo "  1. Edite o CLAUDE.md do projeto com sua stack real"
    echo "  2. cd $(pwd) && claude"
  else
    echo "  1. cd seu-projeto-rails"
    echo "  2. Crie um CLAUDE.md (use examples/rails-api-CLAUDE.md como base)"
    echo "  3. claude"
  fi

  echo ""
  echo -e "  ${CYAN}Dentro do Claude Code:${NC}"
  echo "  /plan \"sua feature\"       → planner + ruby-reviewer"
  echo "  /code-review               → ruby-reviewer automático"
  echo "  \"bundle install failing\"   → rails-build-resolver"
  echo ""
}

# =============================================================================
# MAIN
# =============================================================================

echo ""
echo -e "${BOLD}${BLUE}ECC Rails Adaptation Installer${NC}"
echo -e "Modo: ${CYAN}$MODE${NC}$([ "$DRY_RUN" == true ] && echo " ${YELLOW}(dry-run)${NC}" || echo "")"
echo ""

check_prerequisites

if [[ "$UNINSTALL" == true ]]; then
  uninstall
else
  install_skills
  install_agents
  install_rules
  install_claude_md
  show_summary
fi
