# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:another_user) { create(:user, first_name: "Jane", last_name: "Smith") }

  describe "authentication and authorization" do
    context "when not logged in" do
      it "redirects to login page" do
        get admin_users_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects with unauthorized message" do
        get admin_users_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("admin.unauthorized"))
      end
    end

    context "when logged in as admin" do
      before { sign_in admin_user }

      it "allows access to admin area" do
        get admin_users_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /admin/users" do
    before { sign_in admin_user }

    it "displays list of users" do
      another_user # create user

      get admin_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(another_user.email)
    end
  end

  describe "GET /admin/users/:id" do
    before { sign_in admin_user }

    it "displays user details" do
      get admin_user_path(another_user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(another_user.email)
      expect(response.body).to include(another_user.first_name)
    end
  end

  describe "GET /admin/users/new" do
    before { sign_in admin_user }

    it "displays new user form" do
      get new_admin_user_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/users" do
    before { sign_in admin_user }

    context "with valid params" do
      let(:valid_params) do
        {
          user: {
            email: "newuser@example.com",
            first_name: "New",
            last_name: "User",
            password: "password123",
            password_confirmation: "password123",
            role: "user"
          }
        }
      end

      it "creates a new user" do
        expect {
          post admin_users_path, params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(admin_user_path(User.last))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          user: {
            email: "",
            first_name: "",
            last_name: ""
          }
        }
      end

      it "does not create a user" do
        expect {
          post admin_users_path, params: invalid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    before { sign_in admin_user }

    it "displays edit user form" do
      get edit_admin_user_path(another_user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(another_user.email)
    end
  end

  describe "PATCH /admin/users/:id" do
    before { sign_in admin_user }

    context "with valid params" do
      it "updates the user" do
        patch admin_user_path(another_user), params: {
          user: { first_name: "Updated" }
        }

        expect(response).to redirect_to(admin_user_path(another_user))
        expect(another_user.reload.first_name).to eq("Updated")
      end
    end

    context "with invalid params" do
      it "does not update the user" do
        patch admin_user_path(another_user), params: {
          user: { email: "" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/users/:id" do
    before { sign_in admin_user }

    context "when deleting another user" do
      it "deletes the user" do
        another_user # create user

        expect {
          delete admin_user_path(another_user)
        }.to change(User, :count).by(-1)

        expect(response).to redirect_to(admin_users_path)
      end
    end

    context "when trying to delete self" do
      it "does not delete and shows error" do
        expect {
          delete admin_user_path(admin_user)
        }.not_to change(User, :count)

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:error]).to eq(I18n.t("admin.users.cannot_delete_self"))
      end
    end
  end
end
