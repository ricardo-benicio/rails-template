---
name: rails-verification
description: >
  Verification loops and quality gates for Ruby on Rails. Covers CI/CD pipeline
  setup, database health checks, performance benchmarks, N+1 detection,
  coverage enforcement, and production readiness checklist.
tags: [ruby, rails, ci, testing, performance, n+1, quality-gate]
version: "1.0.0"
---

# Rails Verification Loops

## Quality Gate — Run Before Every PR Merge

```bash
#!/usr/bin/env bash
set -e

echo "=== Rails Quality Gate ==="

# 1. Code style
bundle exec rubocop --parallel

# 2. Security static analysis
bundle exec brakeman --exit-on-warn --no-pager -q

# 3. Dependency vulnerabilities
bundle audit check --update

# 4. Full test suite with coverage
bundle exec rspec --format progress

# 5. N+1 detection (ensure Bullet logs no issues)
BULLET=true bundle exec rspec spec/requests

echo "=== All checks passed ==="
```

---

## CI Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s

    env:
      DATABASE_URL: postgres://postgres:password@localhost/myapp_test
      REDIS_URL: redis://localhost:6379/1
      RAILS_ENV: test

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true

      - name: Set up database
        run: |
          bundle exec rails db:create db:schema:load

      - name: Run RuboCop
        run: bundle exec rubocop --parallel

      - name: Run Brakeman
        run: bundle exec brakeman --exit-on-warn --no-pager -q

      - name: Bundle audit
        run: |
          gem install bundler-audit
          bundle audit check --update

      - name: Run RSpec
        run: bundle exec rspec --format progress

      - name: Check coverage
        run: |
          COVERAGE=$(cat coverage/.last_run.json | jq '.result.covered_percent')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage below 80%"
            exit 1
          fi
```

---

## N+1 Detection (Bullet)

```ruby
# Gemfile
gem "bullet", group: :development

# config/environments/development.rb
config.after_initialize do
  Bullet.enable        = true
  Bullet.alert         = true
  Bullet.rails_logger  = true
  Bullet.add_footer    = true
  Bullet.raise         = Rails.env.test?  # fail tests on N+1
end

# Correct the N+1 when Bullet reports it:
# BEFORE (N+1):
Post.all.each { |post| puts post.author.name }

# AFTER (eager loading):
Post.includes(:author).each { |post| puts post.author.name }

# For conditional associations:
Post.includes(:author, :tags).where(status: "published")

# Use select + joins when you only need a few columns:
Post.joins(:author).select("posts.*, users.name as author_name")
```

---

## Performance Benchmarks

```ruby
# spec/performance/posts_query_spec.rb
RSpec.describe "PostsQuery performance", type: :request do
  before { create_list(:post, 100, :published, :with_comments) }

  it "loads index page in under 200ms" do
    start = Time.current
    get "/api/v1/posts", headers: auth_headers(create(:user))
    elapsed = (Time.current - start) * 1000

    expect(response).to have_http_status(:ok)
    expect(elapsed).to be < 200, "Expected < 200ms, got #{elapsed.round}ms"
  end

  it "does not execute more than 5 queries" do
    query_count = 0
    counter = ->(*, **) { query_count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      get "/api/v1/posts", headers: auth_headers(create(:user))
    end
    expect(query_count).to be <= 5
  end
end
```

---

## Database Health

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def show
    checks = {
      database: database_healthy?,
      redis:    redis_healthy?,
      sidekiq:  sidekiq_healthy?
    }

    status = checks.values.all? ? :ok : :service_unavailable
    render json: { status: status, checks: checks }, status: status
  end

  private

  def database_healthy?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def redis_healthy?
    Redis.new(url: ENV.fetch("REDIS_URL")).ping == "PONG"
  rescue StandardError
    false
  end

  def sidekiq_healthy?
    Sidekiq::ProcessSet.new.size > 0
  rescue StandardError
    false
  end
end
```

---

## Schema Verification

```bash
# Ensure db/schema.rb is in sync with migrations
bundle exec rails db:migrate:status | grep down
# Should return nothing — all migrations must be up

# Ensure schema.rb is committed after migration
git diff --name-only | grep schema.rb
# Should be empty on CI
```

```ruby
# spec/support/database_cleaner.rb — ensure test isolation
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each)  { DatabaseCleaner.start }
  config.after(:each)   { DatabaseCleaner.clean }
end
```

---

## Continuous Monitoring Hooks (RSpec)

```ruby
# spec/support/query_counter.rb
module QueryCounter
  def self.count_queries(&block)
    count = 0
    counter = ->(*) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end

# Usage in specs:
it "loads posts efficiently" do
  queries = QueryCounter.count_queries { get "/api/v1/posts", headers: headers }
  expect(queries).to be <= 5
end
```

---

## Production Readiness Checklist

Before deploying, verify:

- [ ] All migrations run with zero downtime (strong_migrations checked)
- [ ] `RAILS_ENV=production rails assets:precompile` succeeds
- [ ] Health endpoint `/health` returns 200
- [ ] Sidekiq workers start and process a test job
- [ ] All ENV vars set (`bundle exec rails runner "puts 'ok'"` succeeds)
- [ ] SSL/TLS certificate valid
- [ ] CSP headers present (`curl -I https://app.example.com | grep content-security`)
- [ ] Error tracking configured (Sentry/Honeybadger)
- [ ] Log aggregation working (Papertrail/Datadog)
- [ ] Database backups tested and restorable
- [ ] Rate limiting active (`curl` the login endpoint 20 times quickly)
- [ ] `bundle audit check` returns clean
- [ ] `brakeman` returns no HIGH/CRITICAL warnings
- [ ] RSpec coverage ≥ 80%
- [ ] No `TODO`/`FIXME`/`HACK` comments in security-critical paths

---

## RuboCop Configuration

```yaml
# .rubocop.yml
require:
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3
  Exclude:
    - "db/schema.rb"
    - "bin/*"
    - "node_modules/**/*"

Rails:
  Enabled: true

Rails/I18nLocaleTexts:
  Enabled: false  # adjust based on project

RSpec/ExampleLength:
  Max: 20

RSpec/MultipleExpectations:
  Max: 5
```

Run: `bundle exec rubocop -A` to auto-fix safe offenses.
