# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Authentication API", type: :request do
  path "/api/v1/auth/sign_in" do
    post "Sign in" do
      tags "Authentication"
      operationId "signIn"
      description "Authenticate user and receive JWT token"
      consumes "application/json"
      produces "application/json"

      parameter name: :credentials, in: :body, schema: {
        "$ref" => "#/components/schemas/AuthCredentials"
      }

      response "200", "Successfully authenticated" do
        schema type: :object,
               properties: {
                 message: { type: :string },
                 user: { "$ref" => "#/components/schemas/User" }
               },
               required: %w[message user]

        let(:user) { create(:user, password: "password123") }
        let(:credentials) { { user: { email: user.email, password: "password123" } } }

        run_test! do |response|
          expect(response.headers["Authorization"]).to be_present
          expect(json_response[:user][:email]).to eq(user.email)
        end
      end

      response "401", "Invalid credentials" do
        schema "$ref" => "#/components/schemas/Error"

        let(:credentials) { { user: { email: "invalid@example.com", password: "wrong" } } }

        run_test! do
          expect(json_response[:error]).to eq("Invalid email or password.")
        end
      end
    end
  end

  path "/api/v1/auth/sign_out" do
    delete "Sign out" do
      tags "Authentication"
      operationId "signOut"
      description "Invalidate current JWT token"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "Successfully signed out" do
        schema type: :object,
               properties: {
                 message: { type: :string }
               },
               required: %w[message]

        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{generate_jwt(user)}" }

        run_test! do
          expect(json_response[:message]).to eq("Logged out successfully.")
        end
      end

      response "401", "No active session" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }

        run_test!
      end
    end
  end
end
