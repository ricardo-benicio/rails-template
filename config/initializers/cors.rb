# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# CORS (Cross-Origin Resource Sharing) configuration
# This is needed for API access from different origins (frontend apps, mobile apps, etc.)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow all origins
    if Rails.env.development?
      origins "*"
    else
      # In production, specify allowed origins
      origins ENV.fetch("CORS_ALLOWED_ORIGINS", "").split(",").map(&:strip)
    end

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization X-Total-Count X-Page X-Per-Page],
      max_age: 86_400,
      credentials: false
  end
end
