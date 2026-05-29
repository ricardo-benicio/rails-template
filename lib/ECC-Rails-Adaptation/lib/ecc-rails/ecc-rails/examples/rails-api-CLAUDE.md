# CLAUDE.md — Rails API Project

This file is read at the start of every session. It gives the AI agent full
context about this project's stack, conventions, and workflow.

---

## Project Overview

**Type:** Ruby on Rails API + Hotwire frontend  
**Rails version:** 7.2  
**Ruby version:** 3.3.x (see `.ruby-version`)  
**Database:** PostgreSQL 16  
**Background jobs:** Sidekiq + Redis  
**Auth:** Devise + JWT (API) / Devise sessions (HTML)  
**Authorization:** Pundit  
**Test framework:** RSpec + FactoryBot + Capybara  
**Deployment:** Render (production) / Docker Compose (local)

---

## Architecture

```
app/
├── controllers/api/v1/    # API controllers (JSON)
├── controllers/           # HTML controllers (Hotwire/Turbo)
├── models/                # ActiveRecord — validations, associations, scopes
├── services/              # Business logic (plain Ruby objects with Result pattern)
├── queries/               # Complex query objects
├── jobs/                  # Sidekiq background jobs
├── policies/              # Pundit authorization policies
├── serializers/           # JSONAPI serializers
└── mailers/               # ActionMailer
```

---

## Key Conventions

### Service Objects
All business logic goes in `app/services/`. Use the Result pattern:

```ruby
class MyService
  Result = Struct.new(:success?, :data, :errors, keyword_init: true)

  def self.call(...)
    new(...).call
  end

  def call
    # ...
    Result.new(success?: true, data: result, errors: [])
  end
end
```

### API Controllers
- Namespace: `Api::V1::`
- Auth: `before_action :authenticate_user!`
- Authorization: `authorize @resource` on every action
- Response: always use serializers, never `@model.to_json`

### Database
- UUIDs as primary keys (`id: :uuid`)
- All foreign keys have indexes
- Use `strong_migrations` patterns for zero-downtime migrations
- Never add `NOT NULL` column without a default in the same migration

---

## Development Workflow

```bash
# Start development stack
docker compose up -d         # postgres + redis
bundle exec rails server     # Rails
bundle exec sidekiq          # Background jobs

# Database
bundle exec rails db:create db:migrate
bundle exec rails db:seed    # Load development fixtures

# Tests
bundle exec rspec                    # Full suite
bundle exec rspec spec/models/       # Models only
bundle exec rspec spec/requests/     # API specs only
COVERAGE=true bundle exec rspec      # With coverage report

# Code quality
bundle exec rubocop -A               # Auto-fix style
bundle exec brakeman --no-pager      # Security scan
bundle exec rails_best_practices     # Rails conventions
```

---

## Agent Delegation

Use these agents for specialized tasks:

| Task | Agent |
|---|---|
| Feature planning | `planner` |
| Code review | `ruby-reviewer` |
| Security audit | `security-reviewer` |
| Build failures | `rails-build-resolver` |
| TDD guidance | `tdd-guide` |
| Documentation | `doc-updater` |

---

## Environment Variables

Required variables (see `.env.example`):

```
DATABASE_URL=postgres://...
REDIS_URL=redis://localhost:6379/0
DEVISE_JWT_SECRET_KEY=...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
S3_BUCKET=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
SENDGRID_API_KEY=...
SENTRY_DSN=...
```

Never hardcode these. Use `ENV.fetch("VAR_NAME")` (raises if missing).

---

## Database Schema Highlights

Key models and their relationships (update this when schema changes):

- `User` — auth, profile, role (admin/member)
- `Post` belongs_to `User` (author), has_many `Comments`, has_many `Tags` through `PostTags`
- `Comment` belongs_to `Post`, belongs_to `User`
- `Tag` has_many `Posts` through `PostTags`

---

## CI/CD

- **CI:** GitHub Actions (`.github/workflows/ci.yml`)
- Runs: RuboCop → Brakeman → bundle-audit → RSpec
- Coverage must be ≥ 80% or CI fails
- Deploys to Render on merge to `main` (automatic)
- Database migrations run as a pre-deploy step

---

## Known Gotchas

1. **UUIDs in specs** — factories use `SecureRandom.uuid` for IDs; never hardcode
2. **Sidekiq in tests** — use `Sidekiq::Testing.fake!` (set in `spec/rails_helper.rb`)
3. **Time zones** — always use `Time.current` not `Time.now`; DB stores UTC
4. **Turbo Streams** — controllers must `respond_to` both `turbo_stream` and `html`
5. **N+1 in serializers** — Bullet is set to raise in test env; fix before merging
