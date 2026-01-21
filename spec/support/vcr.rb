# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data("<SUPABASE_URL>") { ENV["SUPABASE_URL"] }
  config.filter_sensitive_data("<SUPABASE_ANON_KEY>") { ENV["SUPABASE_ANON_KEY"] }
  config.filter_sensitive_data("<RESEND_API_KEY>") { ENV["RESEND_API_KEY"] }
  config.filter_sensitive_data("<APPSIGNAL_PUSH_API_KEY>") { ENV["APPSIGNAL_PUSH_API_KEY"] }

  # Allow real HTTP connections when no cassette
  config.allow_http_connections_when_no_cassette = false
end

# Disable WebMock by default, VCR will enable it when needed
WebMock.disable_net_connect!(allow_localhost: true)
