# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Users API", type: :request do
  path "/api/v1/users/me" do
    get "Get current user" do
      tags "Users"
      operationId "getCurrentUser"
      description "Returns the currently authenticated user's profile"
      security [ bearer_auth: [] ]
      produces "application/json"

      response "200", "User profile retrieved" do
        schema type: :object,
               properties: {
                 user: { "$ref" => "#/components/schemas/UserExtended" }
               },
               required: %w[user]

        let(:user) { create(:user, first_name: "John", last_name: "Doe") }
        let(:Authorization) { "Bearer #{generate_jwt(user)}" }

        run_test! do
          expect(json_response[:user][:email]).to eq(user.email)
          expect(json_response[:user][:full_name]).to eq("John Doe")
        end
      end

      response "401", "Not authenticated" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "" }

        run_test!
      end
    end

    patch "Update current user" do
      tags "Users"
      operationId "updateCurrentUser"
      description "Updates the currently authenticated user's profile"
      security [ bearer_auth: [] ]
      consumes "application/json"
      produces "application/json"

      parameter name: :user_params, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string }
            }
          }
        },
        required: %w[user]
      }

      response "200", "Profile updated" do
        schema type: :object,
               properties: {
                 message: { type: :string },
                 user: { "$ref" => "#/components/schemas/UserExtended" }
               },
               required: %w[message user]

        let(:user) { create(:user, first_name: "John", last_name: "Doe") }
        let(:Authorization) { "Bearer #{generate_jwt(user)}" }
        let(:user_params) { { user: { first_name: "Jane", last_name: "Smith" } } }

        run_test! do
          expect(json_response[:user][:first_name]).to eq("Jane")
          expect(json_response[:user][:last_name]).to eq("Smith")
        end
      end

      response "422", "Validation error" do
        schema "$ref" => "#/components/schemas/ValidationError"

        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{generate_jwt(user)}" }
        let(:user_params) { { user: { first_name: "" } } }

        run_test! do
          expect(json_response[:errors]).to be_present
        end
      end

      response "401", "Not authenticated" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "" }
        let(:user_params) { { user: { first_name: "Jane" } } }

        run_test!
      end
    end
  end
end
