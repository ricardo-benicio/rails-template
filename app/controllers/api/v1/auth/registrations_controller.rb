# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RegistrationsController < Devise::RegistrationsController
        skip_before_action :verify_authenticity_token
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              message: "Signed up successfully. Please check your email to confirm your account.",
              user: UserBlueprint.render_as_hash(resource)
            }, status: :created
          else
            render json: {
              error: "Sign up failed.",
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def sign_up_params
          params.require(:user).permit(
            :email,
            :password,
            :password_confirmation,
            :first_name,
            :last_name
          )
        end

        def account_update_params
          params.require(:user).permit(
            :email,
            :password,
            :password_confirmation,
            :current_password,
            :first_name,
            :last_name
          )
        end
      end
    end
  end
end
