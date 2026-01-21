# frozen_string_literal: true

require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ============================================
  # Attribute Types
  # ============================================
  # This hash defines the type used to display each attribute
  # on the model's show, index, and form pages.
  ATTRIBUTE_TYPES = {
    id: Field::String.with_options(searchable: false),
    first_name: Field::String,
    last_name: Field::String,
    email: Field::Email,
    role: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.roles.keys }
    ),
    password: Field::Password,
    password_confirmation: Field::Password,

    # Devise trackable
    sign_in_count: Field::Number,
    current_sign_in_at: Field::DateTime,
    last_sign_in_at: Field::DateTime,
    current_sign_in_ip: Field::String,
    last_sign_in_ip: Field::String,

    # Devise confirmable
    confirmed_at: Field::DateTime,
    confirmation_sent_at: Field::DateTime,

    # Devise lockable
    failed_attempts: Field::Number,
    locked_at: Field::DateTime,

    # Timestamps
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # ============================================
  # Collection (Index) Attributes
  # ============================================
  # Attributes displayed on the index page (table view)
  COLLECTION_ATTRIBUTES = %i[
    email
    first_name
    last_name
    role
    confirmed_at
    sign_in_count
    created_at
  ].freeze

  # ============================================
  # Show Attributes
  # ============================================
  # Attributes displayed on the show page
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email
    first_name
    last_name
    role
    confirmed_at
    confirmation_sent_at
    sign_in_count
    current_sign_in_at
    last_sign_in_at
    current_sign_in_ip
    last_sign_in_ip
    failed_attempts
    locked_at
    created_at
    updated_at
  ].freeze

  # ============================================
  # Form Attributes
  # ============================================
  # Attributes on the new/edit forms
  FORM_ATTRIBUTES = %i[
    email
    first_name
    last_name
    role
    password
    password_confirmation
  ].freeze

  # ============================================
  # Filters
  # ============================================
  COLLECTION_FILTERS = {
    role: ->(resources, value) { resources.where(role: value) },
    confirmed: ->(resources, value) {
      value == "true" ? resources.where.not(confirmed_at: nil) : resources.where(confirmed_at: nil)
    },
    locked: ->(resources, value) {
      value == "true" ? resources.where.not(locked_at: nil) : resources.where(locked_at: nil)
    }
  }.freeze

  # ============================================
  # Display Methods
  # ============================================
  # String to display when representing this resource
  def display_resource(user)
    user.full_name.presence || user.email
  end
end
