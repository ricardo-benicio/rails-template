# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth::Registrations", type: :request do
  describe "POST /api/v1/auth/sign_up" do
    let(:valid_params) do
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

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post "/api/v1/auth/sign_up", params: valid_params, headers: json_headers
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response[:user][:email]).to eq("newuser@example.com")
      end

      it "returns unconfirmed user" do
        post "/api/v1/auth/sign_up", params: valid_params, headers: json_headers

        user = User.last
        expect(user.confirmed_at).to be_nil
      end
    end

    context "with invalid parameters" do
      it "returns errors for missing email" do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = ""

        post "/api/v1/auth/sign_up", params: invalid_params, headers: json_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to be_present
      end

      it "returns errors for password mismatch" do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:password_confirmation] = "different"

        post "/api/v1/auth/sign_up", params: invalid_params, headers: json_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns errors for duplicate email" do
        create(:user, email: "newuser@example.com")

        post "/api/v1/auth/sign_up", params: valid_params, headers: json_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
