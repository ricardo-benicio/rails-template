# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  def show?       = member?
  def update?     = owner_or_admin?
  def destroy?    = owner?
  def manage_members? = owner_or_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:account_memberships).where(account_memberships: { user_id: user.id })
    end
  end

  private

  def membership
    @membership ||= record.account_memberships.find_by(user_id: user.id)
  end

  def member?     = membership.present?
  def owner?      = membership&.owner?
  def owner_or_admin? = membership&.owner? || membership&.admin?
end
