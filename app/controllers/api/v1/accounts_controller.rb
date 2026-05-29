# frozen_string_literal: true

module Api
  module V1
    class AccountsController < BaseController
      skip_before_action :set_current_tenant

      before_action :set_account, only: %i[show update destroy]

      def index
        skip_authorization
        accounts = current_user.accounts.kept
        render json: { accounts: AccountBlueprint.render_as_hash(accounts) }, status: :ok
      end

      def show
        authorize @account
        render json: { account: AccountBlueprint.render_as_hash(@account, view: :with_members) }, status: :ok
      end

      def create
        skip_authorization
        account = Account.new(account_params.merge(owner: current_user))
        if account.save
          account.account_memberships.create!(user: current_user, role: :owner)
          render json: { account: AccountBlueprint.render_as_hash(account) }, status: :created
        else
          render_error("Unable to create account.", errors: account.errors.full_messages)
        end
      end

      def update
        authorize @account
        if @account.update(account_params)
          render json: { account: AccountBlueprint.render_as_hash(@account) }, status: :ok
        else
          render_error("Unable to update account.", errors: @account.errors.full_messages)
        end
      end

      def destroy
        authorize @account
        @account.discard
        render json: { message: "Account deleted." }, status: :ok
      end

      private

      def set_account
        @account = current_user.accounts.find(params[:id])
      end

      def account_params
        params.require(:account).permit(:name, :slug)
      end
    end
  end
end
