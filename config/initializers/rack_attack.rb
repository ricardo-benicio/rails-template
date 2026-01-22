# frozen_string_literal: true

# Rack::Attack configuration for rate limiting and blocking
#
# Documentation: https://github.com/rack/rack-attack
#
class Rack::Attack
  # ============================================
  # Cache Store
  # ============================================
  # Use Rails cache store (Redis in production)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # In production, use Redis:
  # Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])

  # ============================================
  # Safelist
  # ============================================
  # Always allow requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  # ============================================
  # Throttle: General API Rate Limit
  # ============================================
  # Limit all API requests to 100 requests per minute per IP
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # ============================================
  # Throttle: Authentication Endpoints
  # ============================================
  # Limit login attempts to 5 per 20 seconds per IP
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/v1/auth/sign_in" && req.post?
      req.ip
    end
  end

  # Limit login attempts to 5 per 20 seconds per email
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/v1/auth/sign_in" && req.post?
      # Normalize email to prevent case-sensitivity bypass
      req.params.dig("user", "email")&.to_s&.downcase&.strip
    end
  end

  # ============================================
  # Throttle: Registration Endpoint
  # ============================================
  # Limit sign up attempts to 3 per minute per IP
  throttle("signups/ip", limit: 3, period: 1.minute) do |req|
    if req.path == "/api/v1/auth/sign_up" && req.post?
      req.ip
    end
  end

  # ============================================
  # Throttle: Password Reset
  # ============================================
  # Limit password reset requests to 5 per hour per IP
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/api/v1/auth/password" && req.post?
      req.ip
    end
  end

  # Limit password reset requests to 5 per hour per email
  throttle("password_reset/email", limit: 5, period: 1.hour) do |req|
    if req.path == "/api/v1/auth/password" && req.post?
      req.params.dig("user", "email")&.to_s&.downcase&.strip
    end
  end

  # ============================================
  # Blocklist
  # ============================================
  # Block requests with suspicious patterns
  blocklist("block-bad-actors") do |req|
    # Block requests trying to access common attack vectors
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      # Flag suspicious requests
      CGI.unescape(req.query_string).match?(/union.*select|<script|\.\.\/|etc\/passwd/i) ||
        req.path.match?(/\.(php|asp|aspx|jsp|cgi)$/i)
    end
  end

  # ============================================
  # Custom Responses
  # ============================================
  # Return 429 Too Many Requests with JSON body for API requests
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    }

    body = {
      error: "Rate limit exceeded",
      retry_after: retry_after
    }.to_json

    [ 429, headers, [ body ] ]
  end

  # Return 403 Forbidden for blocked requests
  self.blocklisted_responder = lambda do |request|
    headers = { "Content-Type" => "application/json" }
    body = { error: "Forbidden" }.to_json

    [ 403, headers, [ body ] ]
  end

  # ============================================
  # Logging (Optional)
  # ============================================
  # Log throttled and blocked requests
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn("[Rack::Attack] Throttled #{req.ip} for #{req.path}")
  end

  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn("[Rack::Attack] Blocked #{req.ip} for #{req.path}")
  end
end
