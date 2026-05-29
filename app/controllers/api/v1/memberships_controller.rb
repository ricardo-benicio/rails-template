# frozen_string_literal: true

module Api
  module V1
    class MembershipsController < BaseController
      before_action :set_account

      def create
        authorize @account, :manage_members?, policy_class: AccountPolicy
        user = User.find_by!(email: params.require(:membership).permit(:email)[:email])
        safe_role = AccountMembership.roles.keys.excluding("owner").include?(requested_role) ? requested_role : "member"
        membership = @account.account_memberships.build(user: user, role: safe_role)

        if membership.save
          render json: { message: "#{user.full_name} added to account.", role: membership.role }, status: :created
        else
          render_error("Unable to add member.", errors: membership.errors.full_messages)
        end
      end

      def destroy
        authorize @account, :manage_members?, policy_class: AccountPolicy
        membership = @account.account_memberships.find(params[:id])
        raise Pundit::NotAuthorizedError if membership.owner?

        membership.destroy
        render json: { message: "Member removed." }, status: :ok
      end

      private

      def set_account
        @account = current_user.accounts.find(params[:account_id])
      end

      def requested_role
        params.dig(:membership, :role).to_s
      end
    end
  end
end
