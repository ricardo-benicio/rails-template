# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Pagy::Backend
      include Pundit::Authorization

      # Skip CSRF for API
      skip_before_action :verify_authenticity_token

      # Authenticate via JWT
      before_action :authenticate_user!

      # Enforce authorization on every action
      after_action :verify_authorized

      # Respond with JSON
      respond_to :json

      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

      private

      # Override Devise method to return 401 for API requests
      def authenticate_user!
        if request.headers["Authorization"].present?
          super
        else
          render json: { error: "Authorization header missing" }, status: :unauthorized
        end
      end

      # Pagination metadata for JSON responses
      def pagination_meta(pagy)
        {
          current_page: pagy.page,
          next_page: pagy.next,
          prev_page: pagy.prev,
          total_pages: pagy.pages,
          total_count: pagy.count,
          per_page: pagy.items
        }
      end

      # Standard error response
      def render_error(message, status: :unprocessable_entity, errors: nil)
        response = { error: message }
        response[:errors] = errors if errors.present?
        render json: response, status: status
      end

      # Standard success response
      def render_success(data = {}, status: :ok, meta: nil)
        response = data
        response[:meta] = meta if meta.present?
        render json: response, status: status
      end

      def render_forbidden
        render json: { error: "Forbidden" }, status: :forbidden
      end
    end
  end
end
