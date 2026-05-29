# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  include Discardable
  has_one_attached :avatar

  # ============================================
  # Devise modules
  # ============================================
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # ============================================
  # Enums
  # ============================================
  enum :role, {
    user: 0,
    manager: 1,
    admin: 2
  }, default: :user, validate: true

  # ============================================
  # Validations
  # ============================================
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # ============================================
  # Callbacks
  # ============================================
  before_create :set_jti

  # ============================================
  # Instance Methods
  # ============================================
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  # JWT payload customization
  def jwt_payload
    {
      "sub" => id,
      "jti" => jti,
      "role" => role,
      "email" => email
    }
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
