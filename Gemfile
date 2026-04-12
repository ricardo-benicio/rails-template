source "https://rubygems.org"

ruby "3.3.6"

# ============================================
# Core Rails
# ============================================
gem "rails", "~> 8.1.2"
gem "propshaft"                    # Modern asset pipeline
gem "pg", "~> 1.1"                 # PostgreSQL adapter
gem "puma", ">= 5.0"               # Web server
gem "bootsnap", require: false     # Reduces boot times through caching

# ============================================
# Frontend (Hotwire + Tailwind)
# ============================================
gem "importmap-rails"              # ESM import maps
gem "turbo-rails"                  # Hotwire SPA-like page accelerator
gem "stimulus-rails"               # Hotwire modest JavaScript framework
gem "tailwindcss-rails"            # Tailwind CSS

# ============================================
# Authentication & Authorization
# ============================================
gem "devise"                       # Authentication solution
gem "devise-jwt"                   # JWT authentication for APIs
gem "bcrypt", "~> 3.1.7"           # Secure password hashing

# ============================================
# Admin Dashboard
# ============================================
gem "administrate"                 # Admin framework

# ============================================
# Background Jobs
# ============================================
gem "sidekiq", "~> 8.1"            # Background job processing
gem "redis", "~> 5.0"              # Redis client for Sidekiq

# ============================================
# Database & Caching (Rails 8 defaults)
# ============================================
gem "solid_cache"                  # Database-backed cache
gem "solid_queue"                  # Database-backed job queue
gem "solid_cable"                  # Database-backed Action Cable

# ============================================
# API & Serialization
# ============================================
gem "rack-cors"                    # CORS handling for API
gem "blueprinter"                  # Fast JSON serialization
gem "rack-attack"                  # Rate limiting and throttling
gem "rswag-api"                    # Swagger API documentation
gem "rswag-ui"                     # Swagger UI for API docs

# ============================================
# Supabase & Storage
# ============================================
gem "image_processing", "~> 1.2"   # Active Storage variants
gem "aws-sdk-s3", require: false   # S3-compatible storage (Supabase)

# ============================================
# Email
# ============================================
gem "resend"                       # Resend email service

# ============================================
# Monitoring & Error Tracking
# ============================================
gem "appsignal"                    # APM and error tracking

# ============================================
# Utilities
# ============================================
gem "pagy", "~> 43.2"              # Fast pagination
gem "discard", "~> 1.3"            # Soft deletes
gem "tzinfo-data", platforms: %i[windows jruby]

# ============================================
# Deployment
# ============================================
gem "kamal", require: false        # Docker deployment
gem "thruster", require: false     # HTTP caching/compression

# ============================================
# Development & Test
# ============================================
group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"               # Environment variables from .env

  # Security
  gem "bundler-audit", require: false
  gem "brakeman", require: false

  # Code quality
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false

  # Testing
  gem "rspec-rails", "~> 8.0"      # RSpec testing framework
  gem "factory_bot_rails"          # Test factories
  gem "faker"                      # Fake data generator

  # API Documentation
  gem "rswag-specs"                # Generate Swagger docs from specs
end

group :development do
  gem "web-console"                # Console on exception pages
  gem "letter_opener"              # Preview emails in browser
  gem "annotate"                   # Annotate models with schema info
  gem "foreman"                    # Process manager for Procfile-based apps
end

group :test do
  gem "shoulda-matchers"           # RSpec matchers for Rails
  gem "simplecov", require: false  # Code coverage
  gem "database_cleaner-active_record" # Clean database between tests
  gem "webmock"                    # Stub HTTP requests
  gem "vcr"                        # Record HTTP interactions
end
