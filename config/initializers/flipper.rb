# frozen_string_literal: true

require "flipper"
require "flipper/adapters/active_record"

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end

# Seed default flags (idempotent)
Rails.application.config.after_initialize do
  Flipper.add(:maintenance_mode)
rescue StandardError
  nil # Gracefully skip if DB not ready (e.g., during asset precompile)
end
