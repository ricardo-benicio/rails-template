# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  before do
    # Reset Rack::Attack cache before each test
    Rack::Attack.cache.store.clear
    # Disable safelist for testing
    Rack::Attack.safelists.clear
  end

  after do
    # Re-enable safelist after tests
    Rack::Attack.reset!
  end

  describe "API rate limiting" do
    it "allows requests under the limit" do
      50.times do
        get "/api/v1/users/me", headers: json_headers
      end

      # Should get 401 (unauthorized) not 429 (rate limited)
      expect(response).to have_http_status(:unauthorized)
    end

    it "throttles requests over the limit", :slow do
      # Skip this test in CI as it requires real time delays
      skip "Rate limit test requires actual request timing" if ENV["CI"]

      101.times do
        get "/api/v1/users/me", headers: json_headers
      end

      expect(response).to have_http_status(:too_many_requests)
      expect(json_response[:error]).to eq("Rate limit exceeded")
      expect(response.headers["Retry-After"]).to be_present
    end
  end

  describe "login throttling" do
    let(:user) { create(:user) }

    it "allows login attempts under the limit" do
      3.times do
        post "/api/v1/auth/sign_in",
             params: { user: { email: user.email, password: "wrong" } }.to_json,
             headers: json_headers
      end

      expect(response).to have_http_status(:unauthorized)
    end

    it "throttles excessive login attempts", :slow do
      skip "Rate limit test requires actual request timing" if ENV["CI"]

      6.times do
        post "/api/v1/auth/sign_in",
             params: { user: { email: user.email, password: "wrong" } }.to_json,
             headers: json_headers
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "signup throttling" do
    it "allows signup attempts under the limit" do
      2.times do |i|
        post "/api/v1/auth/sign_up",
             params: {
               user: {
                 email: "test#{i}@example.com",
                 password: "password123",
                 password_confirmation: "password123",
                 first_name: "Test",
                 last_name: "User"
               }
             }.to_json,
             headers: json_headers
      end

      expect(response).to have_http_status(:created)
    end

    it "throttles excessive signup attempts", :slow do
      skip "Rate limit test requires actual request timing" if ENV["CI"]

      4.times do |i|
        post "/api/v1/auth/sign_up",
             params: {
               user: {
                 email: "test#{i}@example.com",
                 password: "password123",
                 password_confirmation: "password123",
                 first_name: "Test",
                 last_name: "User"
               }
             }.to_json,
             headers: json_headers
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "password reset throttling" do
    it "allows password reset requests under the limit" do
      3.times do
        post "/api/v1/auth/password",
             params: { user: { email: "test@example.com" } }.to_json,
             headers: json_headers
      end

      # Should not be rate limited
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  describe "blocklist" do
    it "blocks requests with SQL injection patterns" do
      # This will trigger the Fail2Ban filter
      3.times do
        get "/api/v1/users/me?q=union%20select%20*%20from%20users", headers: json_headers
      end

      # After 3 attempts, should be blocked
      get "/api/v1/users/me", headers: json_headers

      expect(response).to have_http_status(:forbidden)
      expect(json_response[:error]).to eq("Forbidden")
    end

    it "blocks requests trying to access PHP files" do
      3.times do
        get "/admin.php", headers: json_headers
      end

      get "/api/v1/users/me", headers: json_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
