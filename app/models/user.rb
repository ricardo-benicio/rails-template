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
  devise :omniauthable, omniauth_providers: %i[google_oauth2 github]

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

  def self.from_omniauth(auth)
    find_or_initialize_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email = auth.info.email
      user.first_name = auth.info.first_name || auth.info.name.to_s.split.first || "User"
      user.last_name = auth.info.last_name || auth.info.name.to_s.split.last || auth.uid
      user.password = Devise.friendly_token[0, 20]
      user.skip_confirmation!
    end
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end

  def after_confirmation
    super
    WelcomeEmailJob.perform_later(id)
  end
end
