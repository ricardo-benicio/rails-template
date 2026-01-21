# frozen_string_literal: true

# Resend email service configuration
# https://resend.com/docs/send-with-rails

Resend.api_key = ENV.fetch("RESEND_API_KEY", nil)
