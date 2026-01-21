# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    # ============================================
    # Customizations
    # ============================================

    # Prevent admins from deleting themselves
    def destroy
      if requested_resource == current_user
        flash[:error] = t("admin.users.cannot_delete_self")
        redirect_to admin_users_path
      else
        super
      end
    end

    # ============================================
    # Strong Parameters
    # ============================================

    # Permitted parameters for create
    def permitted_attributes
      super - [ :encrypted_password ] + [ :password, :password_confirmation ]
    end

    # Only allow certain attributes to be updated
    def resource_params
      params.require(:user).permit(*dashboard.permitted_attributes(action_name))
    end
  end
end
