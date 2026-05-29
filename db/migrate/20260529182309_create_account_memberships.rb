# frozen_string_literal: true

class CreateAccountMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :account_memberships, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :role, null: false, default: 2
      t.timestamps
    end

    add_index :account_memberships, [ :account_id, :user_id ], unique: true
  end
end
