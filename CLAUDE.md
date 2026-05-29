# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

- **Ruby 3.3.6** / **Rails 8.1.2**
- **PostgreSQL 16** (+ Supabase-compatible via `DATABASE_URL`)
- **Redis 7** (Sidekiq queues)
- **Tailwind CSS v4** via `tailwindcss-rails` (compiled by Puma plugin — no separate process)
- **Hotwire** (Turbo + Stimulus) + **ImportMap** (no JS bundler)
- **Devise + devise-jwt** (session auth for web, JWT bearer tokens for API)
- **RSpec** for tests, **RuboCop** (`rubocop-rails-omakase`) for linting

## Development

```bash
# Prerequisites: Docker Desktop running
docker compose up -d          # Start Postgres 16 + Redis 7
bin/setup                     # Install gems, create/migrate DB, seed
bin/dev                       # Start dev server (Foreman + Procfile.dev)
```

## Commands

```bash
bin/rspec                     # Full test suite
bundle exec rspec spec/path/to/file_spec.rb   # Single file
bin/rubocop                   # Lint (add -A to auto-fix)
bin/brakeman --no-progress    # Security scan
bin/bundler-audit             # Dependency CVE check
bin/importmap audit           # JS importmap audit
bin/rails rswag:specs:swaggerize  # Regenerate Swagger/OpenAPI docs
```

## Git & PR conventions

- Branch from `develop`: `feature/*`, `fix/*`, `chore/*`
- PRs target `develop`; `develop` → `main` for releases

## API

- Namespace: `/api/v1/`
- Auth: JWT bearer token (`Authorization: Bearer <token>`)
- Serialization: Blueprinter
- Docs: `/api-docs` (Swagger UI)

## Key architecture decisions

- **Dual auth**: Devise sessions for web UI, JWT for `/api/v1/` endpoints
- **Admin**: Administrate gem at `/admin` (role-gated)
- **Soft deletes**: `Discard` gem — use `.kept` scope, never `.all` for user-facing queries
- **Background jobs**: Sidekiq (primary) with Solid Queue as fallback; monitor at `/sidekiq`
- **Pagination**: Pagy — use `include Pagy::Backend` in controllers, `Pagy::Frontend` in helpers
- **Rate limiting**: Rack Attack configured in `config/initializers/rack_attack.rb`
- **Multi-DB in production**: separate databases for cache/queue/cable (Solid* gems)

## Deployment

Kamal (Docker-based). Deploy target: `railstemplate2026.com.br`.

```bash
bin/kamal deploy    # Full deploy
bin/kamal app logs  # Tail production logs
```

`config/deploy.yml` runs `bin/rails db:migrate` as release command automatically.

## Environment

Copy `.env.example` → `.env`. Required for dev:
- `DATABASE_URL` or individual `POSTGRES_*` vars (Docker Compose sets these)
- `REDIS_URL` (Docker Compose default: `redis://localhost:6379/0`)
- `RAILS_MASTER_KEY` (from `config/master.key` — never commit)

## Testing notes

- RSpec with random order and documentation format (`.rspec`)
- Factory Bot + Faker for test data — no fixtures
- `database_cleaner-active_record` truncates between examples
- WebMock/VCR for external HTTP — do not hit real APIs in tests

## PM2 Services

| Port/Name | Service | Type |
|-----------|---------|------|
| 3000 | rails-template-3000 | Rails web server |
| — | rails-template-sidekiq | Sidekiq worker |

```bash
pm2 start ecosystem.config.cjs   # First time
pm2 start all                    # After first time
pm2 stop all / pm2 restart all
pm2 logs / pm2 status / pm2 monit
pm2 save                         # Save process list
pm2 resurrect                    # Restore saved list
```

Claude commands: `/pm2-all`, `/pm2-all-stop`, `/pm2-3000`, `/pm2-sidekiq`, `/pm2-logs`, `/pm2-status`
