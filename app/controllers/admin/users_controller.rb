# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    # ============================================
    # Scopes
    # ============================================

    # Include discarded users when filtering
    def scoped_resource
      if params[:discarded] == "true"
        resource_class.with_discarded
      else
        resource_class
      end
    end

    # ============================================
    # Actions
    # ============================================

    # Soft delete instead of hard delete
    def destroy
      if requested_resource == current_user
        flash[:error] = t("admin.users.cannot_delete_self")
        redirect_to admin_users_path
      else
        requested_resource.discard
        flash[:notice] = t("admin.users.discarded")
        redirect_to admin_users_path
      end
    end

    # Restore soft-deleted user
    def restore
      user = resource_class.with_discarded.find(params[:id])
      user.undiscard
      flash[:notice] = t("admin.users.restored")
      redirect_to admin_user_path(user)
    end

    # Permanently delete user
    def permanently_destroy
      user = resource_class.with_discarded.find(params[:id])

      if user == current_user
        flash[:error] = t("admin.users.cannot_delete_self")
      else
        user.destroy
        flash[:notice] = t("admin.users.permanently_destroyed")
      end

      redirect_to admin_users_path
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
