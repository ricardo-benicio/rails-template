# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        skip_before_action :verify_authenticity_token
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              message: "Logged in successfully.",
              user: UserBlueprint.render_as_hash(resource)
            }, status: :ok
          else
            render json: {
              error: "Invalid email or password."
            }, status: :unauthorized
          end
        end

        def respond_to_on_destroy
          if current_user
            render json: {
              message: "Logged out successfully."
            }, status: :ok
          else
            render json: {
              error: "Couldn't find an active session."
            }, status: :unauthorized
          end
        end
      end
    end
  end
end
