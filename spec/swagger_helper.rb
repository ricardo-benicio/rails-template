# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Rails Template API V1",
        version: "v1",
        description: "API documentation for the Rails Template application",
        contact: {
          name: "API Support",
          email: "support@example.com"
        },
        license: {
          name: "MIT",
          url: "https://opensource.org/licenses/MIT"
        }
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3000",
          description: "Development server"
        },
        {
          url: "https://{environment}.example.com",
          description: "Dynamic server",
          variables: {
            environment: {
              default: "api",
              enum: %w[api staging],
              description: "Server environment"
            }
          }
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT,
            description: "JWT token obtained from /api/v1/auth/sign_in"
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              email: { type: :string, format: :email },
              first_name: { type: :string },
              last_name: { type: :string },
              role: { type: :string, enum: %w[user manager admin] },
              full_name: { type: :string },
              initials: { type: :string }
            },
            required: %w[email first_name last_name]
          },
          UserExtended: {
            allOf: [
              { "$ref" => "#/components/schemas/User" },
              {
                type: :object,
                properties: {
                  confirmed_at: { type: :string, format: "date-time", nullable: true },
                  sign_in_count: { type: :integer },
                  current_sign_in_at: { type: :string, format: "date-time", nullable: true },
                  last_sign_in_at: { type: :string, format: "date-time", nullable: true }
                }
              }
            ]
          },
          AuthCredentials: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  email: { type: :string, format: :email },
                  password: { type: :string, minLength: 6 }
                },
                required: %w[email password]
              }
            },
            required: %w[user]
          },
          RegistrationParams: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  email: { type: :string, format: :email },
                  password: { type: :string, minLength: 6 },
                  password_confirmation: { type: :string, minLength: 6 },
                  first_name: { type: :string },
                  last_name: { type: :string }
                },
                required: %w[email password password_confirmation first_name last_name]
              }
            },
            required: %w[user]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            },
            required: %w[error]
          },
          ValidationError: {
            type: :object,
            properties: {
              error: { type: :string },
              errors: {
                type: :array,
                items: { type: :string }
              }
            },
            required: %w[error]
          }
        }
      },
      tags: [
        { name: "Authentication", description: "User authentication endpoints" },
        { name: "Users", description: "User management endpoints" }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
