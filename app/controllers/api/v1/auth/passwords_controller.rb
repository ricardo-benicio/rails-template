# frozen_string_literal: true

module Api
  module V1
    module Auth
      class PasswordsController < Devise::PasswordsController
        skip_before_action :verify_authenticity_token
        respond_to :json

        # POST /api/v1/auth/password
        def create
          self.resource = resource_class.send_reset_password_instructions(resource_params)
          yield resource if block_given?

          if successfully_sent?(resource)
            render json: {
              message: "Password reset instructions sent to your email."
            }, status: :ok
          else
            render json: {
              error: "Unable to send password reset instructions.",
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PUT /api/v1/auth/password
        def update
          self.resource = resource_class.reset_password_by_token(resource_params)
          yield resource if block_given?

          if resource.errors.empty?
            resource.unlock_access! if unlockable?(resource)
            render json: {
              message: "Password has been reset successfully."
            }, status: :ok
          else
            render json: {
              error: "Unable to reset password.",
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
