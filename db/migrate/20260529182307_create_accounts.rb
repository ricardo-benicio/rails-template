# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.uuid :owner_id, null: false
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :accounts, :discarded_at

    add_index :accounts, :slug, unique: true
    add_index :accounts, :owner_id
    add_foreign_key :accounts, :users, column: :owner_id
  end
end
