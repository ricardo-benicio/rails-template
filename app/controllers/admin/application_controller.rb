# frozen_string_literal: true

module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_admin

    # ============================================
    # Authentication
    # ============================================
    def authenticate_admin
      authenticate_user!
      redirect_to root_path, alert: t("admin.unauthorized") unless current_user&.admin?
    end

    # ============================================
    # Administrate Overrides
    # ============================================

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    def records_per_page
      params[:per_page] || 20
    end

    # Override default sorting to show newest first
    def default_sorting_attribute
      :created_at
    end

    def default_sorting_direction
      :desc
    end

    # ============================================
    # Helpers
    # ============================================

    # Make current_user available to views
    helper_method :current_user

    # Override to use UUID finder
    def find_resource(param)
      resource_class.find(param)
    end
  end
end
