# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Registration API", type: :request do
  path "/api/v1/auth/sign_up" do
    post "Sign up" do
      tags "Authentication"
      operationId "signUp"
      description "Create a new user account"
      consumes "application/json"
      produces "application/json"

      parameter name: :user_params, in: :body, schema: {
        "$ref" => "#/components/schemas/RegistrationParams"
      }

      response "201", "Successfully registered" do
        schema type: :object,
               properties: {
                 message: { type: :string },
                 user: { "$ref" => "#/components/schemas/User" }
               },
               required: %w[message user]

        let(:user_params) do
          {
            user: {
              email: "newuser@example.com",
              password: "password123",
              password_confirmation: "password123",
              first_name: "John",
              last_name: "Doe"
            }
          }
        end

        run_test! do
          expect(json_response[:user][:email]).to eq("newuser@example.com")
          expect(json_response[:message]).to include("Please check your email")
        end
      end

      response "422", "Validation error" do
        schema "$ref" => "#/components/schemas/ValidationError"

        let(:user_params) do
          {
            user: {
              email: "invalid",
              password: "123",
              password_confirmation: "456",
              first_name: "",
              last_name: ""
            }
          }
        end

        run_test! do
          expect(json_response[:errors]).to be_present
        end
      end
    end
  end
end
