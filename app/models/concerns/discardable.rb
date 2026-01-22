# frozen_string_literal: true

# Concern for soft delete functionality using Discard gem
#
# Usage:
#   class Post < ApplicationRecord
#     include Discardable
#   end
#
# This provides:
#   - post.discard     # Soft delete
#   - post.undiscard   # Restore
#   - post.discarded?  # Check if soft deleted
#   - Post.kept        # Records not soft deleted
#   - Post.discarded   # Records soft deleted
#   - Post.with_discarded # All records including soft deleted
#
# Note: You need to add a `discarded_at` column to your table:
#   add_column :posts, :discarded_at, :datetime
#   add_index :posts, :discarded_at
#
module Discardable
  extend ActiveSupport::Concern

  included do
    include Discard::Model

    # By default, only show non-discarded records
    default_scope -> { kept }
  end

  class_methods do
    # Include discarded records in queries
    def with_discarded
      unscope(where: :discarded_at)
    end

    # Only discarded records
    def only_discarded
      with_discarded.discarded
    end
  end
end
