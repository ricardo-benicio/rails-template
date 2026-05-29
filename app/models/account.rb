# frozen_string_literal: true

class Account < ApplicationRecord
  include Discard::Model

  belongs_to :owner, class_name: "User"
  has_many :account_memberships, dependent: :destroy
  has_many :users, through: :account_memberships

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and hyphens" },
                   length: { maximum: 63 }

  before_validation :generate_slug, on: :create, if: -> { slug.blank? }

  private

  def generate_slug
    base = name.to_s.downcase.gsub(/[^a-z0-9\-]/, "-").squeeze("-").delete_prefix("-").delete_suffix("-")
    candidate = base
    counter = 1
    while Account.exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end
end
