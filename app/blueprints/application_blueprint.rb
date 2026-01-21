# frozen_string_literal: true

class ApplicationBlueprint < Blueprinter::Base
  # Default identifier
  identifier :id

  # Common timestamp fields
  field :created_at, datetime_format: "%Y-%m-%dT%H:%M:%S.%LZ"
  field :updated_at, datetime_format: "%Y-%m-%dT%H:%M:%S.%LZ"
end
