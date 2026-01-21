# frozen_string_literal: true

class UserBlueprint < ApplicationBlueprint
  # Default view - minimal info
  fields :email, :first_name, :last_name, :role

  field :full_name do |user|
    user.full_name
  end

  field :initials do |user|
    user.initials
  end

  # Extended view - includes more details
  view :extended do
    field :confirmed_at, datetime_format: "%Y-%m-%dT%H:%M:%S.%LZ"
    field :sign_in_count
    field :current_sign_in_at, datetime_format: "%Y-%m-%dT%H:%M:%S.%LZ"
    field :last_sign_in_at, datetime_format: "%Y-%m-%dT%H:%M:%S.%LZ"
  end

  # Admin view - includes everything
  view :admin do
    include_view :extended

    field :current_sign_in_ip
    field :last_sign_in_ip
    field :failed_attempts
    field :locked_at, datetime_format: "%Y-%m-%dT%H:%M:%S.%LZ"
  end
end
