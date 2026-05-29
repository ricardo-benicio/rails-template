# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  # Own profile or admin
  def show? = own_record? || user.admin?
  def update? = own_record? || user.admin?

  private

  def own_record?
    record == user
  end
end
