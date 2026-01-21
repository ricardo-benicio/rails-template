# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ConfirmationsController < Devise::ConfirmationsController
        skip_before_action :verify_authenticity_token
        respond_to :json

        # POST /api/v1/auth/confirmation
        def create
          self.resource = resource_class.send_confirmation_instructions(resource_params)
          yield resource if block_given?

          if successfully_sent?(resource)
            render json: {
              message: "Confirmation instructions sent to your email."
            }, status: :ok
          else
            render json: {
              error: "Unable to send confirmation instructions.",
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/auth/confirmation?confirmation_token=xxx
        def show
          self.resource = resource_class.confirm_by_token(params[:confirmation_token])
          yield resource if block_given?

          if resource.errors.empty?
            render json: {
              message: "Email confirmed successfully. You can now sign in."
            }, status: :ok
          else
            render json: {
              error: "Unable to confirm email.",
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
