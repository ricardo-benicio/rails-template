# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      # GET /api/v1/users/me
      def me
        authorize current_user, :show?, policy_class: UserPolicy
        render json: {
          user: UserBlueprint.render_as_hash(current_user, view: :extended)
        }, status: :ok
      end

      # PATCH /api/v1/users/me
      def update_me
        authorize current_user, :update?, policy_class: UserPolicy
        if current_user.update(user_params)
          render json: {
            message: "Profile updated successfully.",
            user: UserBlueprint.render_as_hash(current_user, view: :extended)
          }, status: :ok
        else
          render_error(
            "Unable to update profile.",
            errors: current_user.errors.full_messages
          )
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :avatar)
      end
    end
  end
end
