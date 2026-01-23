# Rails Template

A production-ready Rails 8.1 template with authentication, API, admin dashboard, and modern tooling — ready to clone and build on.

## Stack

| Layer | Technology |
|-------|-----------|
| Backend | Rails 8.1, Ruby 3.3, PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4 |
| Auth | Devise + JWT |
| Admin | Administrate |
| Jobs | Sidekiq + Redis |
| API Docs | Swagger/OpenAPI (rswag) |
| Deploy | Kamal, Docker |
| Tests | RSpec, Factory Bot, SimpleCov |
| Monitoring | AppSignal |

## Features

- **Authentication** — Devise with JWT for APIs, email confirmation, password recovery, account lockout
- **Role-based Access** — User, Manager, Admin roles with protected routes
- **REST API v1** — Versioned, paginated, rate-limited, documented
- **Admin Dashboard** — Full CRUD for user management at `/admin`
- **Soft Delete** — Discard gem with reusable concern
- **Rate Limiting** — Rack Attack protecting login, signup, and API endpoints
- **API Documentation** — Swagger UI at `/api-docs`
- **i18n** — English and Brazilian Portuguese

## Getting Started

### Prerequisites

- Ruby 3.3.6
- PostgreSQL 16 (or Docker)
- Redis (optional, for Sidekiq)

### Setup

```bash
# Clone and install dependencies
git clone <repo-url> && cd rails-template
bundle install

# Start PostgreSQL (Docker)
docker run --name postgres-dev \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 -d postgres:16

# Configure environment
cp .env.example .env
# Edit .env with your values (POSTGRES_PASSWORD=postgres)

# Create database and seed
bin/rails db:create db:migrate db:seed

# Start the server
bin/dev
```

Open http://localhost:3000

### Test Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@example.com | password123 |
| Manager | bob@example.com | password123 |
| User | john@example.com | password123 |

## API Endpoints

```
POST   /api/v1/auth/sign_in      # Login (returns JWT)
DELETE /api/v1/auth/sign_out     # Logout
POST   /api/v1/auth/sign_up      # Register
POST   /api/v1/auth/password     # Password reset
GET    /api/v1/users/me          # Current user profile
PATCH  /api/v1/users/me          # Update profile
```

Authentication via `Authorization: Bearer <token>` header.

Full documentation available at `/api-docs`.

## Key URLs

| Path | Description |
|------|-------------|
| `/` | Landing page |
| `/admin` | Admin dashboard (admin only) |
| `/api-docs` | Swagger API docs |
| `/sidekiq` | Job monitoring (admin only) |
| `/up` | Health check |

## Commands

```bash
bin/dev                          # Start development server
bin/rspec                        # Run test suite
bin/rails db:seed                # Seed database
bin/rails rswag:specs:swaggerize # Generate Swagger docs
bin/rubocop                      # Lint code
bin/brakeman                     # Security scan
```

## Project Structure

```
app/
├── controllers/
│   ├── admin/           # Administrate controllers
│   ├── api/v1/          # API controllers (auth, users)
│   └── home_controller  # Landing page
├── models/
│   ├── user.rb          # Devise + JWT + Discard
│   └── concerns/        # Reusable concerns (Discardable)
├── blueprints/          # API serializers (Blueprinter)
├── dashboards/          # Administrate dashboards
└── views/               # ERB templates (Tailwind)

config/
├── routes.rb            # All routes (web, API, admin)
├── initializers/        # Devise, CORS, Rack Attack, rswag
└── locales/             # i18n (en, pt-BR)
```

## Security

- JWT token revocation
- Rate limiting on auth endpoints
- Account lockout after 5 failed attempts
- CORS configuration
- Content Security Policy
- SQL injection protection
- Fail2Ban for suspicious requests

## Deployment

Configured for [Kamal](https://kamal-deploy.org/):

```bash
bin/kamal setup    # First deploy
bin/kamal deploy   # Subsequent deploys
```

## License

MIT
