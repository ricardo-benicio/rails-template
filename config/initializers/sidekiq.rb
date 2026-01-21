# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Configure Sidekiq logger
  config.logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

# Default job options
Sidekiq.default_job_options = {
  retry: 5,
  backtrace: true
}
