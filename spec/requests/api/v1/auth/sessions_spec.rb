# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let(:user) { create(:user, password: "password123") }

  describe "POST /api/v1/auth/sign_in" do
    context "with valid credentials" do
      it "returns success with JWT token" do
        post "/api/v1/auth/sign_in", params: {
          user: { email: user.email, password: "password123" }
        }, headers: json_headers

        expect(response).to have_http_status(:ok)
        expect(response.headers["Authorization"]).to be_present
        expect(json_response[:user][:email]).to eq(user.email)
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized" do
        post "/api/v1/auth/sign_in", params: {
          user: { email: user.email, password: "wrong_password" }
        }, headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to be_present
      end
    end

    context "with unconfirmed user" do
      let(:unconfirmed_user) { create(:user, :unconfirmed, password: "password123") }

      it "returns unauthorized" do
        post "/api/v1/auth/sign_in", params: {
          user: { email: unconfirmed_user.email, password: "password123" }
        }, headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    context "when authenticated" do
      it "returns success" do
        delete "/api/v1/auth/sign_out", headers: authenticated_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:message]).to include("Logged out")
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        delete "/api/v1/auth/sign_out", headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
