---
name: rails-security
description: >
  Security best practices for Ruby on Rails applications. Covers strong parameters,
  mass assignment protection, SQL injection prevention, XSS, CSRF, authentication,
  authorization, secrets management, and OWASP Top 10 for Rails.
tags: [ruby, rails, security, owasp, authentication, authorization, pundit]
version: "1.0.0"
---

# Rails Security

## Core Principles

1. **Strong parameters always** — never `permit!` or mass-assign unfiltered params
2. **Secrets in credentials/env** — never in source code
3. **Authorization on every action** — assume all routes are reachable
4. **Sanitize on output** — not just on input
5. **Keep gems updated** — `bundle audit` in CI

---

## Strong Parameters

```ruby
# NEVER do this
def post_params
  params.require(:post).permit!  # allows all — SQL injection risk
end

# ALWAYS be explicit
def post_params
  params.require(:post).permit(
    :title,
    :body,
    :status,
    tag_ids: []
  )
end

# For nested attributes — be explicit at every level
def user_params
  params.require(:user).permit(
    :name,
    :email,
    address_attributes: [:street, :city, :zip_code]
    # NEVER: address_attributes: {}  — open hash
  )
end
```

---

## SQL Injection Prevention

```ruby
# VULNERABLE — never interpolate user input into SQL
Post.where("title = '#{params[:title]}'")
Post.where("status = #{params[:status]}")

# SAFE — parameterized queries
Post.where(title: params[:title])
Post.where("title = ?", params[:title])
Post.where("title = :title", title: params[:title])

# SAFE — Arel for complex queries
Post.where(Post.arel_table[:title].matches("%#{Post.sanitize_sql_like(params[:q])}%"))

# SAFE — named scope with parameterized condition
scope :search, ->(q) { where("title ILIKE ?", "%#{sanitize_sql_like(q)}%") }
```

---

## Authentication (Devise)

```ruby
# config/initializers/devise.rb — critical settings
Devise.setup do |config|
  config.stretches          = Rails.env.test? ? 1 : 12  # bcrypt cost
  config.password_length    = 12..128
  config.lock_strategy      = :failed_attempts
  config.maximum_attempts   = 10
  config.unlock_strategy    = :time
  config.unlock_in          = 1.hour
  config.timeout_in         = 30.minutes
  config.expire_auth_token_on_timeout = true
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :trackable, :timeoutable

  # Prevent enumeration attacks — always return same message
  def self.find_for_authentication(conditions)
    find_by(conditions)
  end
end
```

---

## Authorization (Pundit)

Every controller action must call `authorize` or `skip_authorization` explicitly.

```ruby
# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def show?
    record.published? || owner_or_admin?
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    owner? || user.admin?
  end

  def publish?
    owner_or_admin? && !record.published?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where("status = 'published' OR author_id = ?", user.id)
      end
    end
  end

  private

  def owner?
    record.author_id == user.id
  end

  def owner_or_admin?
    owner? || user.admin?
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include Pundit::Authorization

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "Not authorized" }, status: :forbidden
  end
end
```

---

## CSRF Protection

```ruby
# For HTML apps — always on
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# For API-only apps using JWT — protect HTML endpoints if mixed
class ApplicationController < ActionController::API
  # CSRF not needed for stateless JWT, but if using sessions:
  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :null_session
end
```

---

## XSS Prevention

```erb
<%# Rails auto-escapes — SAFE by default %>
<p><%= @post.title %></p>

<%# UNSAFE — only use when content is trusted and sanitized %>
<p><%= raw @post.html_body %></p>

<%# SAFER for user-generated rich text %>
<p><%= sanitize @post.html_body, tags: %w[p b i em strong], attributes: %w[href] %></p>
```

```ruby
# Use ActionText for safe rich text with built-in sanitization
class Post < ApplicationRecord
  has_rich_text :body  # ActionText handles sanitization automatically
end
```

---

## Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src     :self, :data
  policy.img_src      :self, :data, "https://storage.example.com"
  policy.object_src   :none
  policy.script_src   :self
  policy.style_src    :self
  policy.connect_src  :self, "wss://cable.example.com" if Rails.env.production?

  policy.report_uri "/csp-violation-report"
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) {
  SecureRandom.base64(16)
}
```

---

## Secrets Management

```bash
# Edit Rails credentials (encrypted, safe to commit)
EDITOR="code --wait" rails credentials:edit

# Structure:
# database:
#   password: your_db_password
# redis:
#   url: redis://...
# stripe:
#   secret_key: sk_live_...
#   webhook_secret: whsec_...
# aws:
#   access_key_id: AKIA...
#   secret_access_key: ...
```

```ruby
# Access in code — never fall back to nil silently
Rails.application.credentials.stripe.secret_key
Rails.application.credentials.dig(:stripe, :secret_key)

# For env-based secrets (Heroku, Render, etc.)
ENV.fetch("STRIPE_SECRET_KEY")  # raises if missing — use fetch, not []
```

---

## HTTP Security Headers

```ruby
# Gemfile
gem "secure_headers"

# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.x_frame_options         = "DENY"
  config.x_content_type_options  = "nosniff"
  config.x_xss_protection        = "1; mode=block"
  config.x_download_options      = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy         = "strict-origin-when-cross-origin"
  config.hsts = "max-age=31536000; includeSubDomains"
end
```

---

## Dependency Audit

```bash
# Add to CI pipeline
bundle exec bundle-audit check --update

# Check for known CVEs in gems
gem install bundler-audit
bundle audit

# Ruby version vulnerabilities
gem install ruby_audit
ruby-audit check
```

```yaml
# .github/workflows/security.yml
- name: Security audit
  run: |
    gem install bundler-audit ruby_audit
    bundle audit check --update
    ruby-audit check
    bundle exec brakeman --no-pager -q
```

---

## Brakeman (Static Analysis)

```bash
# Run locally
bundle exec brakeman

# Run in CI with exit code on warnings
bundle exec brakeman --exit-on-warn --no-pager
```

Common Brakeman findings and fixes:

| Warning | Fix |
|---|---|
| `SQL Injection` | Use parameterized queries |
| `Mass Assignment` | Use strong parameters |
| `Dynamic Render` | Never `render params[:template]` |
| `Redirect` | Validate redirect URLs against allowlist |
| `File Access` | Sanitize filenames, never trust user input |

---

## Rate Limiting

```ruby
# Gemfile
gem "rack-attack"

# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle all requests by IP (100 per minute)
  throttle("req/ip", limit: 100, period: 1.minute) { |req| req.ip }

  # Throttle login attempts (10 per minute per IP)
  throttle("login/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Throttle password resets (5 per hour per email)
  throttle("password-reset/email", limit: 5, period: 1.hour) do |req|
    req.params["user"]&.dig("email")&.downcase if req.path == "/users/password" && req.post?
  end

  self.throttled_responder = lambda do |_env|
    [429, { "Content-Type" => "application/json" },
     [{ error: "Too many requests" }.to_json]]
  end
end
```

---

## OWASP Top 10 Checklist for Rails

| Risk | Rails mitigation |
|---|---|
| A01 Broken Access Control | Pundit policies + `verify_authorized` |
| A02 Cryptographic Failures | Rails credentials + bcrypt (Devise default) |
| A03 Injection | Strong params + parameterized queries + Brakeman |
| A04 Insecure Design | Service objects with explicit validation |
| A05 Security Misconfiguration | `secure_headers` gem + CSP |
| A06 Vulnerable Components | `bundler-audit` + `brakeman` in CI |
| A07 Auth Failures | Devise lockable + rate limiting |
| A08 Integrity Failures | Rails credentials + signed cookies |
| A09 Logging Failures | `lograge` + structured logs (never log passwords) |
| A10 SSRF | Allowlist outbound URLs, never trust user-supplied URLs |
