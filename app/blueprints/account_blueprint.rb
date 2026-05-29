# frozen_string_literal: true

class AccountBlueprint < ApplicationBlueprint
  fields :name, :slug

  field :owner_id

  field :member_count do |account|
    account.account_memberships.count
  end

  view :with_members do
    field :members do |account|
      account.account_memberships.includes(:user).map do |m|
        { id: m.user_id, email: m.user.email, role: m.role }
      end
    end
  end
end
