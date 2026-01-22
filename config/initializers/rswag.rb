# frozen_string_literal: true

# Rswag API configuration
Rswag::Api.configure do |config|
  # Specify a root folder where Swagger JSON files are located
  config.openapi_root = Rails.root.join("swagger").to_s

  # Enable request headers (for Swagger UI)
  config.swagger_filter = lambda { |swagger, _env|
    swagger
  }
end

# Rswag UI configuration
Rswag::Ui.configure do |config|
  # List the Swagger endpoints that you want to be documented through the swagger-ui
  config.openapi_endpoint "/api-docs/v1/swagger.yaml", "API V1 Docs"

  # Configure OAuth2 for Swagger UI (optional)
  # config.config_object[:oauth2RedirectUrl] = "/oauth2-redirect.html"

  # Display operation IDs in Swagger UI
  config.config_object[:displayOperationId] = true

  # Enable "Try it out" by default
  config.config_object[:tryItOutEnabled] = true

  # Persist authorization data
  config.config_object[:persistAuthorization] = true
end
