# frozen_string_literal: true

class AccountMembership < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum :role, { owner: 0, admin: 1, member: 2 }, default: :member, validate: true

  validates :user_id, uniqueness: { scope: :account_id, message: "is already a member" }
end
