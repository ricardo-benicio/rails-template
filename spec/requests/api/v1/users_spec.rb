# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:user) { create(:user, first_name: "John", last_name: "Doe") }

  describe "GET /api/v1/users/me" do
    context "when authenticated" do
      it "returns current user data" do
        get "/api/v1/users/me", headers: authenticated_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:user][:email]).to eq(user.email)
        expect(json_response[:user][:first_name]).to eq("John")
        expect(json_response[:user][:full_name]).to eq("John Doe")
      end

      it "includes extended fields" do
        get "/api/v1/users/me", headers: authenticated_headers(user)

        expect(json_response[:user]).to have_key(:sign_in_count)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/users/me", headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v1/users/me" do
    context "when authenticated" do
      it "updates user profile" do
        patch "/api/v1/users/me",
              params: { user: { first_name: "Jane", last_name: "Smith" } }.to_json,
              headers: authenticated_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:user][:first_name]).to eq("Jane")
        expect(json_response[:user][:last_name]).to eq("Smith")
      end

      it "returns errors for invalid data" do
        patch "/api/v1/users/me",
              params: { user: { first_name: "" } }.to_json,
              headers: authenticated_headers(user)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to be_present
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        patch "/api/v1/users/me",
              params: { user: { first_name: "Jane" } }.to_json,
              headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
