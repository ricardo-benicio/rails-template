# Ruby / Rails Rules

Always follow these principles when working on Ruby on Rails projects.

## Code Style

- `# frozen_string_literal: true` at the top of every Ruby file
- Two-space indentation, no tabs
- Use `&&`/`||` in conditions; `and`/`or` only for flow control (rare)
- Prefer `return` early (guard clauses) over deeply nested `if`
- Max method length: 10 lines. Extract if longer.
- Max class length: 100 lines. Split into concerns or service objects.
- Use `private` for all methods not part of public API

## Rails Conventions

- **Thin controllers** — only params, auth, and render. No business logic.
- **Service objects** for everything that involves more than one model or has side effects
- **Scopes** return `ActiveRecord::Relation` — always chainable, never `nil`
- **Callbacks** (`before_save`, `after_create`) only for model-internal concerns.
  Never send emails, call APIs, or enqueue jobs in a callback — use service objects.
- **Strong parameters** — always explicit. Never `permit!`.
- **`find` vs `find_by`** — `find` raises `RecordNotFound` (use in controllers),
  `find_by` returns `nil` (use in service objects with explicit nil handling)
- Migrations must be **reversible** or use `up`/`down`. Never use `execute` for DDL
  without testing rollback.

## Security (non-negotiable)

- Never interpolate user input into SQL strings
- Never call `permit!` on params
- Every controller action must call `authorize` (Pundit) or `skip_authorization`
- Never store secrets in code — use `Rails.application.credentials` or ENV
- Never use `html_safe` or `raw` on user-supplied content

## Testing

- Write the test before the implementation (TDD)
- Minimum 80% coverage enforced by SimpleCov
- Use `build_stubbed` in unit specs; `create` only when DB persistence is needed
- Request specs for all API endpoints
- One `describe` per class, one `context` per scenario

## Performance

- Use `includes`/`preload` whenever loading associations in a loop
- Use `find_each` (not `all.each`) for batches > 1000 records
- Background jobs for anything taking > 100ms in a request
- Add a database index for every foreign key and every column used in `where`/`order`

## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`
- One logical change per commit
- No migration files without a corresponding schema.rb update committed
- Run `bundle exec rubocop` and `bundle exec rspec` before pushing
