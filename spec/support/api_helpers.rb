# frozen_string_literal: true

module ApiHelpers
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def auth_headers(user)
    token = generate_jwt(user)
    { "Authorization" => "Bearer #{token}" }
  end

  def generate_jwt(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def json_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  def authenticated_headers(user)
    json_headers.merge(auth_headers(user))
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
